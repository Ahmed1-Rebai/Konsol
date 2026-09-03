import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konsol/core/constants/app_constants.dart';
import 'package:konsol/core/utils/haptics.dart';
import 'package:konsol/data/models/host.dart';
import 'package:konsol/data/providers/providers.dart';
import 'package:konsol/features/terminal/controllers/terminal_controller.dart';
import 'package:konsol/features/terminal/models/session_tab_key.dart';
import 'package:konsol/features/terminal/screens/terminal_screen.dart';

/// Session hub that hosts multiple concurrent SSH terminal sessions as tabs.
///
/// Route: `/terminal/:id` — opens [initialHostId] as the first tab and lets
/// the user add/remove tabs for other (or the same) hosts.
class SessionHostScreen extends ConsumerStatefulWidget {
  final String initialHostId;

  const SessionHostScreen({super.key, required this.initialHostId});

  @override
  ConsumerState<SessionHostScreen> createState() => _SessionHostScreenState();
}

class _SessionHostScreenState extends ConsumerState<SessionHostScreen>
    with TickerProviderStateMixin {
  TabController? _tabBarController;
  final List<SessionTabKey> _tabs = [];

  @override
  void initState() {
    super.initState();
    _openTab(SessionTabKey(hostId: widget.initialHostId, instance: 1));
  }

  int _nextInstance(String hostId) {
    var max = 0;
    for (final t in _tabs) {
      if (t.hostId == hostId && t.instance > max) max = t.instance;
    }
    return max + 1;
  }

  void _openTab(SessionTabKey key) {
    setState(() {
      final index = _tabs.length;
      _tabs.add(key);
      _replaceController(
        TabController(length: index + 1, vsync: this, initialIndex: index),
      );
    });
  }

  void _replaceController(TabController controller) {
    _tabBarController?.dispose();
    _tabBarController = controller
      ..addListener(() {
        if (mounted) setState(() {});
      });
  }

  void _closeTab(int index) {
    if (_tabs.length == 1) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _tabs.removeAt(index);
      _replaceController(TabController(
        length: _tabs.length,
        vsync: this,
        initialIndex: index.clamp(0, _tabs.length - 1),
      ));
    });
  }

  void _addTab() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetCtx) => _HostPicker(
        hosts: ref.read(hostsProvider),
        onSelect: (host) {
          Navigator.of(sheetCtx).pop();
          Haptics.connect();
          _openTab(
            SessionTabKey(hostId: host.id, instance: _nextInstance(host.id)),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabBarController?.dispose();
    super.dispose();
  }

  Host? _hostFor(SessionTabKey key, List<Host> hosts) {
    for (final h in hosts) {
      if (h.id == key.hostId) return h;
    }
    return null;
  }

  String _tabLabel(Host? host, SessionTabKey key) {
    if (host == null) return 'unknown';
    final sameHost = _tabs.where((t) => t.hostId == host.id).length;
    return sameHost > 1 ? '${host.name} ${key.instance}' : host.name;
  }

  @override
  Widget build(BuildContext context) {
    final hosts = ref.watch(hostsProvider);
    final activeIndex = _tabBarController?.index ?? 0;
    final activeKey = _tabs.isEmpty ? null : _tabs[activeIndex.clamp(0, _tabs.length - 1)];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.surface,
      ),
      child: Scaffold(
        backgroundColor: AppColors.terminalBackground,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 52,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        itemCount: _tabs.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 6),
                        itemBuilder: (context, i) {
                          final key = _tabs[i];
                          return _SessionTab(
                            label: _tabLabel(_hostFor(key, hosts), key),
                            sessionKey: key,
                            selected: i == activeIndex,
                            onTap: () => _tabBarController?.animateTo(i),
                            onClose: () => _closeTab(i),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 22),
                      color: AppColors.textSecondary,
                      onPressed: _addTab,
                      tooltip: 'New session',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: _tabs.isEmpty
            ? const SizedBox.shrink()
            : Column(
                children: [
                  if (activeKey != null) _SessionStatusStrip(sessionKey: activeKey),
                  Expanded(
                    child: TabBarView(
                      controller: _tabBarController!,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 0; i < _tabs.length; i++)
                          TerminalSessionView(
                            key: ValueKey<String>(_tabs[i].cacheKey),
                            sessionKey: _tabs[i],
                            onClose: () => _closeTab(i),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// One tab chip, tinted by the live status of the session it points at.
class _SessionTab extends ConsumerWidget {
  final String label;
  final SessionTabKey sessionKey;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _SessionTab({
    required this.label,
    required this.sessionKey,
    required this.selected,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(terminalControllerProvider(sessionKey));

    return Material(
      color: selected ? AppColors.surfaceLight : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: selected ? AppColors.borderStrong : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatusDot(status: status),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClose,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                  child: Icon(Icons.close_rounded,
                      size: 14, color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final TerminalStatus status;

  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      TerminalStatus.connected => AppColors.success,
      TerminalStatus.connecting => AppColors.warning,
      TerminalStatus.disconnected => AppColors.textTertiary,
      TerminalStatus.error => AppColors.error,
    };

    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: status == TerminalStatus.connected
            ? AppShadows.glow(color, opacity: 0.6)
            : null,
      ),
    );
  }
}

/// Thin line under the tabs naming who you are on the active session.
class _SessionStatusStrip extends ConsumerWidget {
  final SessionTabKey sessionKey;

  const _SessionStatusStrip({required this.sessionKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(terminalControllerProvider(sessionKey));
    final ctrl = ref.read(terminalControllerProvider(sessionKey).notifier);
    final host = ctrl.host;
    if (host == null) return const SizedBox.shrink();

    final label = switch (status) {
      TerminalStatus.connected => 'connected',
      TerminalStatus.connecting => 'connecting',
      TerminalStatus.disconnected => 'disconnected',
      TerminalStatus.error => 'failed',
    };

    return Container(
      height: 28,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${host.username}@${host.address}:${host.port}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11.5,
                color: AppColors.textTertiary,
              ),
            ),
          ),
          _StatusDot(status: status),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HostPicker extends StatelessWidget {
  final List<Host> hosts;
  final ValueChanged<Host> onSelect;

  const _HostPicker({required this.hosts, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'New session',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: hosts.length,
              itemBuilder: (context, i) {
                final host = hosts[i];
                final color = AppColors
                    .hostColors[host.colorIndex % AppColors.hostColors.length];

                return ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(Icons.dns_outlined, size: 18, color: color),
                  ),
                  title: Text(
                    host.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    '${host.username}@${host.displayAddress}',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12.5,
                    ),
                  ),
                  onTap: () => onSelect(host),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
