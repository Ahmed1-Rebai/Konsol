import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konsol/data/providers/providers.dart';
import 'package:konsol/data/models/host.dart';
import 'package:konsol/data/repositories/ssh_service.dart';
import 'package:konsol/features/terminal/models/session_tab_key.dart';
import 'package:konsol/features/terminal/services/path_completer.dart';
import 'package:konsol/features/terminal/services/welcome_banner.dart';
import 'package:xterm/xterm.dart';

enum TerminalStatus {
  connecting,
  connected,
  disconnected,
  error,
}

/// Bridges a live SSH PTY session with an xterm.dart [Terminal].
class TerminalSessionController extends StateNotifier<TerminalStatus> {
  final SessionTabKey key;
  final Ref ref;

  /// Created once and never replaced: the [TerminalView] in the widget tree
  /// binds to this exact instance, so swapping it on (re)connect would leave
  /// the view attached to a terminal that nothing ever writes to.
  final Terminal terminal = Terminal(maxLines: 2000);

  SshSessionHandle? _handle;
  StreamSubscription<String>? _stdoutSub;
  StreamSubscription<String>? _stderrSub;
  bool _disposed = false;

  /// Reason of the last failure, surfaced by the error overlay.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Path suggestions for whatever the user is currently typing.
  final ValueNotifier<List<PathCompletion>> completions = ValueNotifier([]);

  PathCompleter? _completer;
  Timer? _completionDebounce;
  int _completionRequest = 0;

  /// Best-effort reconstruction of the line being typed, built from the
  /// keystrokes we send rather than from the echoed output.
  final StringBuffer _line = StringBuffer();

  /// The full-screen program the remote shell appears to be running, so the
  /// UI can offer its save/quit shortcuts instead of leaving the user to
  /// hunt for the right control sequence. Null when the shell is just a
  /// normal prompt.
  final ValueNotifier<String?> activeProgram = ValueNotifier(null);

  /// The command word of the line last submitted, kept until the terminal
  /// either confirms it opened a full-screen program (by switching to the
  /// alternate buffer) or the shell prompt returns without ever doing so.
  String? _pendingProgram;

  /// Command names whose full-screen UI we know the exit sequence for.
  /// Anything not in here still gets caught by [TerminalStatus] — this only
  /// gates the contextual save/quit bar.
  static const Set<String> _knownPrograms = {
    'nano', 'pico',
    'vim', 'vi', 'nvim', 'view',
    'less', 'more', 'most', 'man',
    'htop', 'top', 'btop', 'atop', 'gtop',
  };

  /// Whether the server's own post-connect banner (MOTD, last-login line,
  /// etc.) has already been replaced with [WelcomeBanner] — true when the
  /// setting is off or hasn't been armed yet, so [_onRemoteOutput] has
  /// nothing to do.
  bool _bannerCleared = true;
  Timer? _bannerClearTimer;

  /// Waits for the login banner to actually finish printing — rather than
  /// clearing on a fixed delay — by resetting a short idle timer on every
  /// chunk of output, capped so a chatty server can't stall it forever.
  void _armBannerClear() {
    _bannerCleared = false;
    _bannerClearTimer?.cancel();
    _bannerClearTimer = Timer(const Duration(milliseconds: 2500), _flushBannerClear);
  }

  void _onRemoteOutput() {
    if (_bannerCleared) return;
    _bannerClearTimer?.cancel();
    _bannerClearTimer = Timer(const Duration(milliseconds: 450), _flushBannerClear);
  }

  void _flushBannerClear() {
    if (_bannerCleared || _disposed) return;
    _bannerCleared = true;
    // Escape codes only — nothing is sent to the remote, so the shell's own
    // scrollback and history are untouched; only Konsol's local view wipes.
    terminal.write('\x1b[H\x1b[2J\x1b[3J');
    final h = host;
    if (h != null) terminal.write(WelcomeBanner.build(h));
  }

  static String? _recognizeProgram(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    final words = trimmed.split(RegExp(r'\s+'));
    var i = 0;
    // Skip leading env assignments (FOO=bar nano file).
    while (i < words.length && RegExp(r'^[\w]+=').hasMatch(words[i])) {
      i++;
    }
    if (i < words.length && (words[i] == 'sudo' || words[i] == 'sudoedit')) {
      i++;
      while (i < words.length && words[i].startsWith('-')) {
        i++;
      }
    }
    if (i >= words.length) return null;

    var cmd = words[i];
    final slash = cmd.lastIndexOf('/');
    if (slash >= 0) cmd = cmd.substring(slash + 1);
    cmd = cmd.toLowerCase();
    return _knownPrograms.contains(cmd) ? cmd : null;
  }

  Host? get host {
    final hosts = ref.read(hostsProvider);
    for (final h in hosts) {
      if (h.id == key.hostId) return h;
    }
    return null;
  }

  TerminalSessionController(this.key, this.ref)
      : super(TerminalStatus.connecting) {
    terminal.onOutput = (data) {
      // The remote side speaks bytes: encode as UTF-8 so accented and
      // non-latin characters survive instead of being truncated to their
      // UTF-16 code units.
      _handle?.write(utf8.encode(data));
      _trackInput(data);
    };
    terminal.onResize = (w, h, pw, ph) {
      _handle?.resize(w, h);
    };
    // The parser has finished handling a chunk by the time this fires, so
    // isUsingAltBuffer already reflects any smcup/rmcup escape it contained.
    terminal.addListener(_onTerminalChanged);
  }

  void _onTerminalChanged() {
    if (terminal.isUsingAltBuffer) {
      if (activeProgram.value == null && _pendingProgram != null) {
        activeProgram.value = _pendingProgram;
      }
    } else if (activeProgram.value != null) {
      activeProgram.value = null;
    }
  }

  Future<void> connect() async {
    _errorMessage = null;
    state = TerminalStatus.connecting;

    await _teardown();

    // Clear screen + scrollback so a reconnect starts on a clean view while
    // keeping the same terminal instance.
    terminal.write('\x1b[H\x1b[2J\x1b[3J');

    try {
      final host = this.host;
      if (host == null) {
        throw const SshConnectionException('Host no longer exists.');
      }

      final secure = ref.read(secureStorageProvider);
      final password = host.authMethod == 'password'
          ? await secure.getPassword(host.id)
          : null;

      final handle = await ref.read(sshServiceProvider).connect(
            host,
            password: password,
            keyId: host.keyId,
            keyRepository: ref.read(keyRepositoryProvider),
            width: terminal.viewWidth,
            height: terminal.viewHeight,
          );

      // The provider may have been disposed while awaiting (e.g. the user
      // left the screen mid-handshake). Bail out without touching state.
      if (_disposed) {
        unawaited(handle.close());
        return;
      }

      _handle = handle;
      _completer = PathCompleter(handle);

      // The view may have been laid out (and the terminal resized) while the
      // handshake was in flight, so re-sync the remote PTY with it.
      handle.resize(terminal.viewWidth, terminal.viewHeight);

      // Decoding through Utf8Decoder as a stream transformer writes every
      // chunk straight to the terminal while still carrying a multi-byte
      // character split across packets over to the next chunk.
      _stdoutSub = handle.stdout
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(
            (data) {
              terminal.write(data);
              _onRemoteOutput();
            },
            onError: (Object e, StackTrace s) => _onError(e),
            onDone: () {
              if (!_disposed && state != TerminalStatus.error) {
                state = TerminalStatus.disconnected;
              }
            },
          );

      // A PTY normally folds stderr into stdout, but anything the server does
      // send as extended data would otherwise pile up unread.
      _stderrSub = handle.stderr
          .cast<List<int>>()
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen(terminal.write, onError: (Object e, StackTrace s) {});

      state = TerminalStatus.connected;
      ref.read(hostsProvider.notifier).updateLastConnected(host.id);

      final showWelcomeBanner =
          ref.read(settingsProvider)['welcomeBanner'] as bool? ?? true;
      if (showWelcomeBanner) _armBannerClear();
    } on SshConnectionException catch (e) {
      _onError(e);
    } catch (e) {
      _onError(SshConnectionException(e.toString()));
    }
  }

  // --- path completion ------------------------------------------------------

  /// Mirrors the keystrokes we send so we know what the current command line
  /// looks like without having to parse the echoed terminal output.
  void _trackInput(String data) {
    var changed = false;
    for (var i = 0; i < data.length; i++) {
      final char = data[i];
      final code = char.codeUnitAt(0);

      if (char == '\r' || char == '\n') {
        final line = _line.toString();
        _completer?.noteCommand(line);
        _pendingProgram = _recognizeProgram(line);
        _resetLine();
        changed = true;
      } else if (code == 0x7f || code == 0x08) {
        final current = _line.toString();
        if (current.isNotEmpty) {
          _setLine(current.substring(0, current.length - 1));
          changed = true;
        }
      } else if (code == 0x1b || char == '\t') {
        // Escape sequences (arrows, history) and remote tab-completion both
        // rewrite the line in ways we can't follow — stop guessing.
        _resetLine();
        changed = true;
        break;
      } else if (code < 0x20) {
        // Ctrl-C, Ctrl-U, Ctrl-L and friends all abandon the current line.
        _resetLine();
        changed = true;
      } else {
        _line.write(char);
        changed = true;
      }
    }
    if (changed) _scheduleCompletion();
  }

  void _resetLine() {
    _line.clear();
    _completionDebounce?.cancel();
    _completionRequest++;
    if (completions.value.isNotEmpty) completions.value = const [];
  }

  void _setLine(String value) {
    _line
      ..clear()
      ..write(value);
  }

  void _scheduleCompletion() {
    _completionDebounce?.cancel();
    final fragment = PathCompleter.fragmentOf(_line.toString());
    if (fragment == null || _handle == null || terminal.isUsingAltBuffer) {
      _completionRequest++;
      if (completions.value.isNotEmpty) completions.value = const [];
      return;
    }
    _completionDebounce = Timer(const Duration(milliseconds: 220), () {
      _runCompletion(fragment);
    });
  }

  Future<void> _runCompletion(String fragment) async {
    final completer = _completer;
    if (completer == null || _disposed) return;

    final request = ++_completionRequest;
    final results = await completer.complete(fragment);

    // Drop results that a newer keystroke has already invalidated.
    if (_disposed || request != _completionRequest) return;
    completions.value = results;
  }

  /// Types the rest of [completion] into the remote shell.
  void applyCompletion(PathCompletion completion) {
    final handle = _handle;
    if (handle == null) return;

    final text = PathCompleter.escapeForShell(completion.insertion);
    handle.write(utf8.encode(text));
    _line.write(completion.insertion);
    completions.value = const [];
    // A directory usually isn't the destination — offer what's inside it.
    if (completion.isDirectory) _scheduleCompletion();
  }

  void dismissCompletions() {
    _completionDebounce?.cancel();
    _completionRequest++;
    completions.value = const [];
  }

  Future<void> _teardown() async {
    _completionDebounce?.cancel();
    _completionRequest++;
    _completer = null;
    _line.clear();
    completions.value = const [];
    _pendingProgram = null;
    activeProgram.value = null;
    _bannerClearTimer?.cancel();
    _bannerCleared = true;

    final stdoutSub = _stdoutSub;
    final stderrSub = _stderrSub;
    final handle = _handle;
    _stdoutSub = null;
    _stderrSub = null;
    _handle = null;
    await stdoutSub?.cancel();
    await stderrSub?.cancel();
    await handle?.close();
  }

  void _onError(Object error) {
    if (_disposed) return;
    _errorMessage = error.toString();
    unawaited(_teardown());
    state = TerminalStatus.error;
  }

  @override
  void dispose() {
    _disposed = true;
    terminal.removeListener(_onTerminalChanged);
    unawaited(_teardown());
    completions.dispose();
    activeProgram.dispose();
    super.dispose();
  }
}

final terminalControllerProvider = StateNotifierProvider.autoDispose
    .family<TerminalSessionController, TerminalStatus, SessionTabKey>(
  (ref, key) {
    final controller = TerminalSessionController(key, ref);
    controller.connect();
    ref.onDispose(controller.dispose);
    return controller;
  },
);
