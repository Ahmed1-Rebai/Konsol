import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:konsol/core/constants/app_constants.dart';
import 'package:konsol/data/providers/providers.dart';
import 'package:konsol/features/hosts/widgets/widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    final themeMode = (settings['themeMode'] ?? 'dark').toString();
    final fontSize = settings['defaultFontSize']?.toDouble() ?? 14.0;
    final scheme = (settings['terminalColorScheme'] ?? 'default').toString();
    final welcomeBanner = settings['welcomeBanner'] as bool? ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Appearance'),
          _SettingsCard(
            children: [
              _RadioTile<String>(
                icon: Icons.dark_mode_outlined,
                title: 'Dark',
                subtitle: 'Preferred at night',
                value: 'dark',
                groupValue: themeMode,
                onChanged: (v) =>
                    notifier.updateSetting('themeMode', v),
              ),
              _RadioTile<String>(
                icon: Icons.light_mode_outlined,
                title: 'Light',
                subtitle: 'Bright surface',
                value: 'light',
                groupValue: themeMode,
                onChanged: (v) =>
                    notifier.updateSetting('themeMode', v),
              ),
              _RadioTile<String>(
                icon: Icons.brightness_auto_outlined,
                title: 'System',
                subtitle: 'Follow device setting',
                value: 'system',
                groupValue: themeMode,
                onChanged: (v) =>
                    notifier.updateSetting('themeMode', v),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader('Terminal'),
          _SettingsCard(
            children: [
              _RadioTile<String>(
                icon: Icons.palette_outlined,
                title: 'Konsol',
                subtitle: 'Neon cyan and mint on deep navy',
                value: 'default',
                groupValue: scheme,
                onChanged: (v) =>
                    notifier.updateSetting('terminalColorScheme', v),
              ),
              _RadioTile<String>(
                icon: Icons.nights_stay_outlined,
                title: 'Tokyo Night',
                subtitle: 'Muted purples and blues',
                value: 'tokyo',
                groupValue: scheme,
                onChanged: (v) =>
                    notifier.updateSetting('terminalColorScheme', v),
              ),
              _RadioTile<String>(
                icon: Icons.terminal,
                title: 'Green on Black',
                subtitle: 'Retro phosphor look',
                value: 'green',
                groupValue: scheme,
                onChanged: (v) =>
                    notifier.updateSetting('terminalColorScheme', v),
              ),
              const Divider(height: 1),
              _FontSizeTile(fontSize: fontSize, notifier: notifier),
              const Divider(height: 1),
              _SwitchTile(
                icon: Icons.auto_awesome_outlined,
                title: 'Welcome banner',
                subtitle:
                    "Show the Konsol banner instead of the server's login message",
                value: welcomeBanner,
                onChanged: (v) => notifier.updateSetting('welcomeBanner', v),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader('About'),
          _SettingsCard(
            children: [
              const ListTile(
                leading: KonsolMark(size: 32, glow: false),
                title: Text('Konsol'),
                subtitle: Text('Connect. SSH. Control.'),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Version'),
                trailing: const Text('0.1.0', style: TextStyle(fontSize: 13)),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final T value;
  final T groupValue;
  final ValueChanged<T> onChanged;

  const _RadioTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? AppColors.accent
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 20,
              color: selected
                  ? AppColors.accent
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: value
                  ? AppColors.accent
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _FontSizeTile extends StatelessWidget {
  final double fontSize;
  final SettingsNotifier notifier;

  const _FontSizeTile({required this.fontSize, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.format_size),
          title: const Text('Terminal font size'),
          trailing: Text(
            '${fontSize.round()}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Slider(
            value: fontSize,
            min: 10,
            max: 20,
            divisions: 10,
            activeColor: AppColors.accent,
            label: '${fontSize.round()}',
            onChanged: (v) => notifier.updateSetting('defaultFontSize', v),
          ),
        ),
      ],
    );
  }
}
