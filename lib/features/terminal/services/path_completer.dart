import 'dart:async';
import 'dart:convert';

import 'package:konsol/data/repositories/ssh_service.dart';

/// A single completion candidate for the path fragment the user is typing.
class PathCompletion {
  /// The full path as it should end up on the command line.
  final String value;

  /// What still needs to be typed to turn the fragment into [value].
  final String insertion;

  final bool isDirectory;

  const PathCompletion({
    required this.value,
    required this.insertion,
    required this.isDirectory,
  });

  /// Just the last segment, which is what the chip shows.
  String get label {
    final trimmed = isDirectory && value.length > 1
        ? value.substring(0, value.length - 1)
        : value;
    final slash = trimmed.lastIndexOf('/');
    final name = slash >= 0 ? trimmed.substring(slash + 1) : trimmed;
    return name.isEmpty ? trimmed : name;
  }
}

/// Completes filesystem paths by asking the remote host to glob them.
///
/// This is plain shell globbing over a second SSH channel — no prediction and
/// no model: every candidate is a path that really exists on the server.
class PathCompleter {
  PathCompleter(this._handle);

  final SshSessionHandle _handle;

  /// Commands whose bare (slash-less) arguments are worth completing.
  static const _pathCommands = {
    'cd', 'ls', 'll', 'cat', 'less', 'more', 'tail', 'head', 'vim', 'vi',
    'nano', 'rm', 'cp', 'mv', 'touch', 'mkdir', 'rmdir', 'chmod', 'chown',
    'du', 'df', 'stat', 'file', 'source', 'bash', 'sh', 'python', 'python3',
    'tar', 'unzip', 'scp', 'rsync', 'grep', 'find', 'diff', 'ln', 'export',
  };

  String? _home;
  String _cwd = '.';
  bool _probed = false;

  /// Remembers where the interactive shell moved to, so relative fragments
  /// resolve against the same directory the user sees in their prompt.
  void noteCommand(String line) {
    final match = RegExp(r'^\s*cd\s*(.*)$').firstMatch(line);
    if (match == null) return;
    final target = match.group(1)!.trim().replaceAll(RegExp('''['"]'''), '');
    if (target.isEmpty || target == '~') {
      _cwd = _home ?? '~';
    } else if (target.startsWith('/') || target.startsWith('~')) {
      _cwd = target;
    } else if (target == '..') {
      final slash = _cwd.lastIndexOf('/');
      _cwd = slash > 0 ? _cwd.substring(0, slash) : _cwd;
    } else {
      _cwd = _cwd.endsWith('/') ? '$_cwd$target' : '$_cwd/$target';
    }
  }

  /// The fragment being typed at the end of [line], or null when the line
  /// can't usefully be completed.
  static String? fragmentOf(String line) {
    if (line.trim().isEmpty) return null;
    // Only the last simple segment matters: everything before a pipe, a
    // separator or a redirect belongs to another command.
    final tail = line.split(RegExp(r'[|;&]|&&|\|\|')).last;
    if (tail.trimLeft().isEmpty) return null;

    final words = tail.trimLeft().split(RegExp(r'\s+'));
    final command = words.first;
    final fragment = tail.endsWith(' ') ? '' : words.last;

    // The first word is the command itself, not an argument.
    if (words.length == 1 && !tail.endsWith(' ')) {
      return fragment.contains('/') ? fragment : null;
    }
    if (fragment.startsWith('-')) return null;
    if (fragment.contains('/') || fragment.startsWith('~')) return fragment;
    if (fragment.isEmpty) return null;
    return _pathCommands.contains(command) ? fragment : null;
  }

  /// Escapes a fragment for use inside single quotes in the remote shell.
  static String _quote(String value) =>
      "'${value.replaceAll("'", r"'\''")}'";

  /// Escapes the characters that would otherwise break the command line the
  /// completion is inserted into.
  static String escapeForShell(String value) =>
      value.replaceAllMapped(RegExp(r'''[ '"\\()\[\]{}$&;|<>*?`!#~]'''),
          (m) => '\\${m[0]}');

  Future<void> _probe() async {
    if (_probed) return;
    _probed = true;
    try {
      final out = await _handle.runCommand(r'printf "%s\n%s\n" "$HOME" "$PWD"');
      final lines = const LineSplitter().convert(out);
      if (lines.isNotEmpty && lines[0].startsWith('/')) _home = lines[0];
      if (_cwd == '.' && lines.length > 1 && lines[1].startsWith('/')) {
        _cwd = lines[1];
      }
    } catch (_) {
      // Completion is a convenience; a server that refuses the extra channel
      // simply gets no suggestions.
    }
  }

  /// Globs [fragment] on the remote host and returns what it matches.
  Future<List<PathCompletion>> complete(String fragment) async {
    await _probe();

    final absolute = fragment.startsWith('/') || fragment.startsWith('~');
    final base = absolute ? fragment : '$_cwd/$fragment';

    final patterns = <String>[];
    void addPattern(String path) {
      // Keep `~` outside the quotes so the remote shell still expands it.
      if (path.startsWith('~')) {
        patterns.add('~${_quote(path.substring(1))}*');
      } else {
        patterns.add('${_quote(path)}*');
      }
    }

    addPattern(base);
    if (!base.endsWith('/')) addPattern('$base/');

    final command =
        'ls -1dp -- ${patterns.join(' ')} 2>/dev/null | head -n 40';

    final String raw;
    try {
      raw = await _handle.runCommand(command);
    } catch (_) {
      return const [];
    }

    final seen = <String>{};
    final results = <PathCompletion>[];
    for (final line in const LineSplitter().convert(raw)) {
      final path = line.trimRight();
      if (path.isEmpty || !seen.add(path)) continue;

      final isDirectory = path.endsWith('/');
      // Present the candidate the same way the user is typing it.
      var display = path;
      if (!absolute && path.startsWith('$_cwd/')) {
        display = path.substring(_cwd.length + 1);
      } else if (fragment.startsWith('~') && _home != null &&
          path.startsWith('$_home/')) {
        display = '~${path.substring(_home!.length)}';
      }

      if (!display.startsWith(fragment)) continue;
      final insertion = display.substring(fragment.length);
      if (insertion.isEmpty) continue;

      results.add(PathCompletion(
        value: display,
        insertion: insertion,
        isDirectory: isDirectory,
      ));
    }

    // Directories first — they are what a half-typed path usually leads to.
    results.sort((a, b) {
      if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
      return a.value.length.compareTo(b.value.length);
    });
    return results.take(24).toList();
  }
}
