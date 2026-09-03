import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konsol/core/constants/app_constants.dart';
import 'package:konsol/core/utils/haptics.dart';
import 'package:konsol/data/models/host.dart';
import 'package:konsol/data/providers/providers.dart';
import 'package:konsol/features/hosts/widgets/widgets.dart';

class HostListScreen extends ConsumerStatefulWidget {
  const HostListScreen({super.key});

  @override
  ConsumerState<HostListScreen> createState() => _HostListScreenState();
}

class _HostListScreenState extends ConsumerState<HostListScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hosts = ref.watch(hostsProvider);
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? hosts
        : hosts
            .where((h) =>
                h.name.toLowerCase().contains(query) ||
                h.address.toLowerCase().contains(query) ||
                h.username.toLowerCase().contains(query))
            .toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: hosts.isEmpty
            ? const _EmptyState()
            : Column(
                children: [
                  _Header(count: hosts.length),
                  _SearchField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  Expanded(
                    child: visible.isEmpty
                        ? const _NoMatches()
                        : RefreshIndicator(
                            color: AppColors.accent,
                            backgroundColor: AppColors.surface,
                            onRefresh: () async =>
                                ref.read(hostsProvider.notifier).refresh(),
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(top: 4, bottom: 110),
                              itemCount: visible.length,
                              itemBuilder: (context, index) {
                                final host = visible[index];
                                final color = AppColors.hostColors[
                                    host.colorIndex % AppColors.hostColors.length];

                                return HostTile(
                                  name: host.name,
                                  address: host.displayAddress,
                                  username: host.username,
                                  port: host.port,
                                  authMethod: host.authMethod,
                                  color: color,
                                  lastConnectedAt: host.lastConnectedAt,
                                  isPinned: host.isPinned,
                                  onTap: () {
                                    Haptics.connect();
                                    context.push('/terminal/${host.id}');
                                  },
                                  onLongPress: () {
                                    Haptics.light();
                                    _showContextSheet(host);
                                  },
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: _ConnectFab(onTap: () => context.push('/add')),
    );
  }

  void _showContextSheet(Host host) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(host.name,
                    style: Theme.of(sheetContext).textTheme.titleMedium),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit host'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/edit/${host.id}');
              },
            ),
            ListTile(
              leading: Icon(host.isPinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin_rounded),
              title: Text(host.isPinned ? 'Unpin' : 'Pin to top'),
              onTap: () {
                Navigator.pop(sheetContext);
                Haptics.light();
                ref.read(hostsProvider.notifier).togglePin(host.id);
              },
            ),
            const Divider(indent: 16, endIndent: 16),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(host);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Host host) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete host?'),
        content: Text(
          '${host.name} will be removed. Its saved password, if any, is '
          'deleted from the device keychain too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              Haptics.error();
              if (host.authMethod == 'password') {
                await ref.read(secureStorageProvider).deletePassword(host.id);
              }
              await ref.read(hostsProvider.notifier).deleteHost(host.id);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int count;

  const _Header({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 14),
      child: Row(
        children: [
          const KonsolMark(size: 34),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Konsol', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 1),
              Text(
                '$count ${count == 1 ? 'host' : 'hosts'} · connect · ssh · control',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined),
            tooltip: 'SSH keys',
            onPressed: () => context.push('/keys'),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search hosts',
          prefixIcon: const Icon(Icons.search_rounded, size: 19),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 17),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

/// Gradient call-to-action that echoes the mark's colour ramp.
class _ConnectFab extends StatelessWidget {
  final VoidCallback onTap;

  const _ConnectFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        gradient: const LinearGradient(colors: AppColors.brandGradient),
        boxShadow: AppShadows.glow(AppColors.accent, opacity: 0.4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.full),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 20, color: Color(0xFF03151F)),
                SizedBox(width: 7),
                Text(
                  'Add host',
                  style: TextStyle(
                    color: Color(0xFF03151F),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No host matches that search.',
        style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const KonsolMark(size: 108),
            const SizedBox(height: 30),
            Text('No hosts yet', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 10),
            const Text(
              'Add your first machine and Konsol keeps it a tap away — '
              'credentials stay in the device keychain.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 28),
            _ConnectFab(onTap: () => context.push('/add')),
          ],
        ),
      ),
    );
  }
}

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
}
