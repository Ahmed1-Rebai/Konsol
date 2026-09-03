import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konsol/core/constants/app_constants.dart';
import 'package:konsol/core/utils/haptics.dart';
import 'package:konsol/data/models/ssh_key.dart';
import 'package:konsol/data/providers/providers.dart';

class KeyManagerScreen extends ConsumerStatefulWidget {
  const KeyManagerScreen({super.key});

  @override
  ConsumerState<KeyManagerScreen> createState() => _KeyManagerScreenState();
}

class _KeyManagerScreenState extends ConsumerState<KeyManagerScreen> {
  bool _busy = false;

  Future<void> _generateKey() async {
    final name = await _prompt('Key name', initial: 'My ed25519 key');
    if (name == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final key = await ref
          .read(keysProvider.notifier)
          .generateEd25519(name: name.isEmpty ? null : name);
      if (mounted) _showPublicKeySheet(key);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importKey() async {
    final pem = await _promptMulti('Paste private key (PEM)', '-----BEGIN …');
    if (pem == null || pem.trim().isEmpty || !mounted) return;

    setState(() => _busy = true);
    try {
      final key = await ref
          .read(keysProvider.notifier)
          .importFromPem(pem.trim());
      if (mounted) _showPublicKeySheet(key);
    } catch (e) {
      if (mounted) _showError('Invalid key: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showPublicKeySheet(SSHKey key) {
    Haptics.success();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your new key', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Generated successfully. Copy the public key below and '
                'add it to ~/.ssh/authorized_keys on your server.',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  key.publicKey,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                    color: Color(0xFFD5D6DB),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: key.publicKey),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<T?> _prompt<T>(
    String title, {
    String? initial,
    bool obscure = false,
  }) {
    final controller = TextEditingController(text: initial ?? '');
    return showDialog<T>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          obscureText: obscure,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Required'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptMulti(String title, String hint) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 8,
          autofocus: true,
          style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12),
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    Haptics.error();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _keyOptions(SSHKey key) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              title: Text(
                key.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${key.keyType.toUpperCase()} • created ${key.createdAt.day}/${key.createdAt.month}/${key.createdAt.year}',
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.content_copy_outlined),
              title: const Text('Copy public key'),
              onTap: () async {
                Navigator.pop(ctx);
                await Clipboard.setData(ClipboardData(text: key.publicKey));
                _showSnack('Public key copied');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () async {
                Navigator.pop(ctx);
                final newName = await _prompt('Rename key', initial: key.name);
                if (newName != null && newName.isNotEmpty && mounted) {
                  await ref.read(keysProvider.notifier).rename(key.id, newName);
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete', style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(key);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(SSHKey key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete key?'),
        content: Text('${key.name} and its private key will be permanently removed. Hosts using it will need a new key.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Haptics.error();
              await ref.read(keysProvider.notifier).delete(key.id);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final keys = ref.watch(keysProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Key Manager'),
        backgroundColor: Colors.transparent,
      ),
      body: keys.isEmpty
          ? _EmptyKeys(
              busy: _busy,
              onGenerate: _generateKey,
              onImport: _importKey,
            )
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ...keys.map(
                  (k) => _KeyTile(
                    key: ValueKey(k.id),
                    sshKey: k,
                    onTap: () => _keyOptions(k),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _importKey,
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Import existing key'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentLight,
                      side: const BorderSide(color: AppColors.accent),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _busy ? null : _generateKey,
        icon: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add),
        label: Text(_busy ? 'Generating…' : 'Generate key'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}

class _KeyTile extends StatelessWidget {
  final SSHKey sshKey;
  final VoidCallback onTap;

  const _KeyTile({
    super.key,
    required this.sshKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.key, size: 20, color: AppColors.accentLight),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sshKey.name, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    '${sshKey.keyType.toUpperCase()} • SSH${sshKey.publicKey.length > 8 ? sshKey.publicKey.substring(0, sshKey.publicKey.indexOf(' ') > 0 ? sshKey.publicKey.indexOf(' ') : 8) : sshKey.publicKey}…',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyKeys extends StatelessWidget {
  final bool busy;
  final VoidCallback onGenerate;
  final VoidCallback onImport;

  const _EmptyKeys({
    required this.busy,
    required this.onGenerate,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.key, size: 40, color: AppColors.accentLight),
            ),
            const SizedBox(height: 24),
            Text('No keys yet', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Generate an ed25519 key or import one you already have.\nKeys unlock passwordless SSH.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: busy ? null : onGenerate,
                icon: const Icon(Icons.add),
                label: Text(busy ? 'Generating…' : 'Generate ed25519 key'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Import existing key'),
            ),
          ],
        ),
      ),
    );
  }
}
