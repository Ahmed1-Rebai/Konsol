import 'package:flutter/material.dart';
import 'package:konsol/core/constants/app_constants.dart';

/// The product mark, rendered from the brand asset with a soft bloom behind it.
class KonsolMark extends StatelessWidget {
  final double size;
  final bool glow;

  const KonsolMark({super.key, this.size = 32, this.glow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: glow
            ? AppShadows.glow(AppColors.accent, opacity: 0.28)
            : null,
      ),
      child: Image.asset(
        'assets/brand/mark.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// Square host badge: the host's initial over its own accent colour.
class KonsolAvatar extends StatelessWidget {
  final String name;
  final Color color;
  final double size;

  const KonsolAvatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A saved host, presented as a card with its connection details.
class HostTile extends StatelessWidget {
  final String name;
  final String address;
  final String username;
  final int port;
  final String authMethod;
  final Color color;
  final DateTime? lastConnectedAt;
  final bool isPinned;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const HostTile({
    super.key,
    required this.name,
    required this.address,
    required this.username,
    required this.color,
    this.port = 22,
    this.authMethod = 'password',
    this.lastConnectedAt,
    this.isPinned = false,
    this.onTap,
    this.onLongPress,
  });

  String _relativeTime(DateTime? time) {
    if (time == null) return 'never connected';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDark ? AppColors.border : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                KonsolAvatar(name: name, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          if (isPinned) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.push_pin_rounded,
                              size: 13,
                              color: color.withValues(alpha: 0.8),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '$username@$address',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          _Meta(
                            icon: authMethod == 'key'
                                ? Icons.vpn_key_rounded
                                : Icons.lock_rounded,
                            label: authMethod == 'key' ? 'key' : 'password',
                          ),
                          const SizedBox(width: 8),
                          _Meta(
                            icon: Icons.schedule_rounded,
                            label: _relativeTime(lastConnectedAt),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(Icons.play_arrow_rounded, size: 18, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
