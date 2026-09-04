import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konsol/core/constants/app_constants.dart';
import 'package:konsol/core/theme/terminal_theme.dart';
import 'package:konsol/core/utils/haptics.dart';
import 'package:konsol/data/providers/providers.dart';
import 'package:konsol/features/terminal/controllers/terminal_controller.dart';
import 'package:konsol/features/terminal/models/session_tab_key.dart';
import 'package:konsol/features/terminal/services/path_completer.dart';
import 'package:xterm/xterm.dart';

/// A single SSH terminal session bound to a [SessionTabKey].
///
/// Used inside the multi-session [SessionHostScreen] tab body.
class TerminalSessionView extends ConsumerStatefulWidget {
  final SessionTabKey sessionKey;
  final VoidCallback? onClose;

  const TerminalSessionView({
    super.key,
    required this.sessionKey,
    this.onClose,
  });

  @override
  ConsumerState<TerminalSessionView> createState() =>
      _TerminalSessionViewState();
}

class _TerminalSessionViewState extends ConsumerState<TerminalSessionView>
    with AutomaticKeepAliveClientMixin {
  final _controllerNode = TerminalController();
  final _focusNode = FocusNode();
  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _controllerNode.dispose();
    _focusNode.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final status = ref.watch(terminalControllerProvider(widget.sessionKey));
    final ctrl =
        ref.read(terminalControllerProvider(widget.sessionKey).notifier);

    final settings = ref.watch(settingsProvider);
    final fontSize = (settings['defaultFontSize']?.toDouble() ?? 14.0);
    final scheme = settings['terminalColorScheme']?.toString();
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return ColoredBox(
      color: AppColors.terminalBackground,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: TerminalView(
                    ctrl.terminal,
                    controller: _controllerNode,
                    theme: TermThemes.resolve(scheme),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    textStyle: TerminalStyle(
                      fontSize: fontSize,
                      fontFamily: 'JetBrainsMono',
                      fontFamilyFallback: const ['Menlo', 'Monaco', 'monospace'],
                    ),
                    focusNode: _focusNode,
                    autofocus: true,
                    scrollController: _scroll,
                    backgroundOpacity: 1,
                  ),
                ),
                if (status == TerminalStatus.connecting)
                  const _ConnectingOverlay()
                else if (status == TerminalStatus.error)
                  _StatusOverlay(
                    icon: Icons.error_outline_rounded,
                    color: AppColors.error,
                    title: 'Connection failed',
                    message: ctrl.errorMessage ?? _hostDetail(ctrl),
                    primaryLabel: 'Retry',
                    onPrimary: () => ctrl.connect(),
                    secondaryLabel: 'Close session',
                    onSecondary: widget.onClose,
                  )
                else if (status == TerminalStatus.disconnected)
                  _StatusOverlay(
                    icon: Icons.link_off_rounded,
                    color: AppColors.textSecondary,
                    title: 'Connection dropped',
                    message: 'The SSH session was interrupted.',
                    primaryLabel: 'Reconnect',
                    onPrimary: () => ctrl.connect(),
                    secondaryLabel: 'Close session',
                    onSecondary: widget.onClose,
                  ),
              ],
            ),
          ),
          if (status == TerminalStatus.connected) ...[
            _ProgramActionBar(controller: ctrl),
            _CompletionBar(controller: ctrl),
            if (keyboardOpen) _QuickKeyBar(terminal: ctrl.terminal),
          ],
        ],
      ),
    );
  }

  String _hostDetail(TerminalSessionController ctrl) {
    final h = ctrl.host;
    if (h == null) return 'Heartbeat lost.';
    return '${h.username}@${h.address}:${h.port}';
  }
}

/// One tappable action for the program [_ProgramActionBar] is showing —
/// e.g. nano's "Save & Exit" — expressed as raw key/text input so it works
/// the same regardless of what's actually bound to those keys remotely.
class _ProgramAction {
  final String label;
  final IconData icon;
  final bool primary;
  final bool warn;
  final void Function(Terminal terminal) run;

  const _ProgramAction(
    this.label,
    this.icon,
    this.run, {
    this.primary = false,
    this.warn = false,
  });
}

final List<_ProgramAction> _nanoActions = [
  _ProgramAction('Save', Icons.save_outlined, (t) {
    t.charInput(0x6f, ctrl: true); // ^O — Write Out
    t.keyInput(TerminalKey.enter); // confirm the current filename
  }),
  _ProgramAction('Save & exit', Icons.check_circle_rounded, (t) {
    t.charInput(0x6f, ctrl: true);
    t.keyInput(TerminalKey.enter);
    t.charInput(0x78, ctrl: true); // ^X — Exit
  }, primary: true),
  _ProgramAction('Exit w/o saving', Icons.delete_outline_rounded, (t) {
    t.charInput(0x78, ctrl: true); // ^X — Exit; if modified, nano asks Y/N
    t.textInput('n'); // discard — a no-op keystroke if it wasn't asked
  }, warn: true),
];

final List<_ProgramAction> _vimActions = [
  _ProgramAction('Save', Icons.save_outlined, (t) {
    t.keyInput(TerminalKey.escape);
    t.textInput(':w');
    t.keyInput(TerminalKey.enter);
  }),
  _ProgramAction('Save & exit', Icons.check_circle_rounded, (t) {
    t.keyInput(TerminalKey.escape);
    t.textInput(':wq');
    t.keyInput(TerminalKey.enter);
  }, primary: true),
  _ProgramAction('Quit w/o saving', Icons.delete_outline_rounded, (t) {
    t.keyInput(TerminalKey.escape);
    t.textInput(':q!');
    t.keyInput(TerminalKey.enter);
  }, warn: true),
];

final List<_ProgramAction> _quitOnlyActions = [
  _ProgramAction('Quit', Icons.close_rounded, (t) {
    t.textInput('q');
  }, primary: true),
];

List<_ProgramAction> _actionsFor(String program) {
  switch (program) {
    case 'nano':
    case 'pico':
      return _nanoActions;
    case 'vim':
    case 'vi':
    case 'nvim':
    case 'view':
      return _vimActions;
    default:
      // less, more, most, man, htop, top, btop, atop, gtop — all quit on 'q'.
      return _quitOnlyActions;
  }
}

/// Save/quit shortcuts for whatever full-screen program the shell appears to
/// be running — recognized from the command line that opened it, shown for
/// as long as the terminal stays on the alternate screen buffer. Visible
/// even with the keyboard closed, since "save and get out of nano" is
/// exactly the moment a user's thumb is done typing.
class _ProgramActionBar extends StatelessWidget {
  final TerminalSessionController controller;

  const _ProgramActionBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller.activeProgram,
      builder: (context, program, _) {
        if (program == null) return const SizedBox.shrink();
        final actions = _actionsFor(program);

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const Icon(Icons.terminal_rounded,
                  size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                program,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (final action in actions) ...[
                      _ProgramActionButton(
                        action: action,
                        onTap: () {
                          Haptics.light();
                          action.run(controller.terminal);
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgramActionButton extends StatelessWidget {
  final _ProgramAction action;
  final VoidCallback onTap;

  const _ProgramActionButton({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = action.primary
        ? const Color(0xFF04212B)
        : action.warn
            ? AppColors.error
            : AppColors.textPrimary;

    return Material(
      color: action.primary
          ? AppColors.accent
          : action.warn
              ? AppColors.error.withValues(alpha: 0.12)
              : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal strip of real remote paths matching what the user is typing.
class _CompletionBar extends StatelessWidget {
  final TerminalSessionController controller;

  const _CompletionBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PathCompletion>>(
      valueListenable: controller.completions,
      builder: (context, items, _) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 46,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(
                Icons.account_tree_outlined,
                size: 15,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 6),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final tint =
                        item.isDirectory ? AppColors.accent : AppColors.textSecondary;

                    return Material(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        onTap: () {
                          Haptics.light();
                          controller.applyCompletion(item);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Icon(
                                item.isDirectory
                                    ? Icons.folder_rounded
                                    : Icons.description_outlined,
                                size: 14,
                                color: tint,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontFamily: 'JetBrainsMono',
                                  fontSize: 12.5,
                                  color: tint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, color: AppColors.textTertiary),
                onPressed: controller.dismissCompletions,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The keys a phone keyboard doesn't have but a shell can't do without.
class _QuickKeyBar extends StatelessWidget {
  final Terminal terminal;

  const _QuickKeyBar({required this.terminal});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          _key('esc', onTap: () => terminal.keyInput(TerminalKey.escape)),
          _key('tab', onTap: () => terminal.keyInput(TerminalKey.tab)),
          _key('^C', onTap: () => terminal.charInput(0x63, ctrl: true)),
          _key('^D', onTap: () => terminal.charInput(0x64, ctrl: true)),
          _key('^Z', onTap: () => terminal.charInput(0x7a, ctrl: true)),
          _key('^L', onTap: () => terminal.charInput(0x6c, ctrl: true)),
          _icon(Icons.keyboard_arrow_up_rounded,
              onTap: () => terminal.keyInput(TerminalKey.arrowUp)),
          _icon(Icons.keyboard_arrow_down_rounded,
              onTap: () => terminal.keyInput(TerminalKey.arrowDown)),
          _icon(Icons.keyboard_arrow_left_rounded,
              onTap: () => terminal.keyInput(TerminalKey.arrowLeft)),
          _icon(Icons.keyboard_arrow_right_rounded,
              onTap: () => terminal.keyInput(TerminalKey.arrowRight)),
          for (final symbol in const ['/', '-', '~', '|', '\$', '*'])
            _key(symbol, onTap: () => terminal.textInput(symbol)),
        ],
      ),
    );
  }

  Widget _wrap({required Widget child, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () {
            Haptics.light();
            onTap();
          },
          child: Container(
            constraints: const BoxConstraints(minWidth: 40),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _key(String label, {required VoidCallback onTap}) => _wrap(
        onTap: onTap,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'JetBrainsMono',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );

  Widget _icon(IconData icon, {required VoidCallback onTap}) => _wrap(
        onTap: onTap,
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      );
}

class _ConnectingOverlay extends StatelessWidget {
  const _ConnectingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.86),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.glow(AppColors.accent, opacity: 0.25),
              ),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Establishing secure channel',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            const Text(
              'Negotiating keys and opening a shell…',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusOverlay extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _StatusOverlay({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: AppColors.background.withValues(alpha: 0.93),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(height: 18),
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onPrimary,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(primaryLabel),
                  ),
                ),
                if (secondaryLabel != null && onSecondary != null) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: onSecondary,
                    child: Text(
                      secondaryLabel!,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
