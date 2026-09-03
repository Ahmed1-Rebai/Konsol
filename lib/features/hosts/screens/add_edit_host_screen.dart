import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:konsol/core/constants/app_constants.dart';
import 'package:konsol/data/models/host.dart';
import 'package:konsol/data/providers/providers.dart';

class AddEditHostScreen extends ConsumerStatefulWidget {
  final String? hostId;

  const AddEditHostScreen({super.key, this.hostId});

  @override
  ConsumerState<AddEditHostScreen> createState() => _AddEditHostScreenState();
}

class _AddEditHostScreenState extends ConsumerState<AddEditHostScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  String _authMethod = 'password';
  String? _selectedKeyId;
  int _colorIndex = 0;
  bool _isEditing = false;
  Host? _existing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.hostId != null;

    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _portController = TextEditingController(text: '22');
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();

    if (_isEditing) {
      final hosts = ref.read(hostsProvider);
      _existing = hosts.firstWhere(
        (h) => h.id == widget.hostId,
        orElse: () => throw Exception('Host not found'),
      );
      _nameController.text = _existing!.name;
      _addressController.text = _existing!.address;
      _portController.text = _existing!.port.toString();
      _usernameController.text = _existing!.username;
      _authMethod = _existing!.authMethod;
      _selectedKeyId = _existing!.keyId;
      _colorIndex = _existing!.colorIndex;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Host' : 'New Host'),
        backgroundColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Color picker row
            _ColorPicker(
              selectedIndex: _colorIndex,
              onSelected: (i) => setState(() => _colorIndex = i),
            ),
            const SizedBox(height: 32),

            _SectionLabel(text: 'HOST DETAILS'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'e.g. Ubuntu VM',
              icon: Icons.dns_outlined,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              hint: 'e.g. 192.168.1.100',
              icon: Icons.lan_outlined,
              keyboardType: TextInputType.url,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Enter an address' : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    hint: 'e.g. root or ubuntu',
                    icon: Icons.person_outline,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter a username' : null,
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 110,
                  child: _buildTextField(
                    controller: _portController,
                    label: 'Port',
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.isEmpty) return null;
                      final p = int.tryParse(v);
                      if (p == null || p < 1 || p > 65535) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            _SectionLabel(text: 'AUTHENTICATION'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: 'Password',
                      icon: Icons.lock_outline,
                      selected: _authMethod == 'password',
                      onTap: () => setState(() => _authMethod = 'password'),
                    ),
                  ),
                  Expanded(
                    child: _SegmentButton(
                      label: 'SSH Key',
                      icon: Icons.key_outlined,
                      selected: _authMethod == 'key',
                      onTap: () => setState(() => _authMethod = 'key'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_authMethod == 'password') ...[
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                hint: _isEditing ? 'Leave blank to keep existing' : 'Enter your password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              Text(
                'Stored securely in the device keychain.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ] else ...[
              _KeyPicker(
                selectedKeyId: _selectedKeyId,
                onSelect: (keyId) {
                  setState(() => _selectedKeyId = keyId);
                },
              ),
            ],

            const SizedBox(height: 40),

            // Save button
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(_isEditing ? 'Save Changes' : 'Add Host'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      cursorColor: AppColors.accent,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.4))
            : null,
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_authMethod == 'key' && _selectedKeyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an SSH key or switch to password.')),
      );
      return;
    }

    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 22;
    final username = _usernameController.text.trim();
    final secure = ref.read(secureStorageProvider);
    final password = _passwordController.text;

    String id;
    if (_isEditing && _existing != null) {
      id = _existing!.id;
      final updated = _existing!.copyWith(
        name: name,
        address: address,
        port: port,
        username: username,
        authMethod: _authMethod,
        keyId: _selectedKeyId,
        colorIndex: _colorIndex,
      );
      await ref.read(hostsProvider.notifier).updateHost(updated);
    } else {
      id = await ref.read(hostsProvider.notifier).addHost(
            name: name,
            address: address,
            port: port,
            username: username,
            authMethod: _authMethod,
            keyId: _selectedKeyId,
            colorIndex: _colorIndex,
          );
    }

    // Persist credentials based on chosen auth method.
    if (_authMethod == 'password') {
      if (password.isNotEmpty) {
        await secure.savePassword(id, password);
      }
    } else if (password.isNotEmpty) {
      // Field is not shown for key auth, but defensively clear any old password.
      await secure.deletePassword(id);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ColorPicker({
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(text: 'COLOR TAG'),
        const SizedBox(height: 8),
        Row(
          children: List.generate(AppColors.hostColors.length, (i) {
            final color = AppColors.hostColors[i];
            final isSelected = i == selectedIndex;
            return GestureDetector(
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: AppDurations.normal,
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(right: 8),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 2.5)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyPicker extends ConsumerWidget {
  final String? selectedKeyId;
  final ValueChanged<String> onSelect;

  const _KeyPicker({required this.selectedKeyId, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final keys = ref.watch(keysProvider);

    if (keys.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.key_outlined, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No keys yet. Create one in Key Manager.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.push('/keys'),
              child: const Text('Manage'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final key in keys)
            InkWell(
              onTap: () => onSelect(key.id),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      selectedKeyId == key.id
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      size: 20,
                      color: selectedKeyId == key.id
                          ? AppColors.accent
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.key, size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(key.name, style: theme.textTheme.bodyLarge),
                          Text(
                            key.keyType.toUpperCase(),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Manage keys'),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () => context.push('/keys'),
          ),
        ],
      ),
    );
  }
}
