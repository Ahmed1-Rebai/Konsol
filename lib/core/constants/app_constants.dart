import 'package:flutter/material.dart';

/// Konsol design tokens.
///
/// The palette is sampled from the product mark: neon cyan and mint over a
/// deep navy field, with an electric blue as the cool counterweight.
class AppColors {
  AppColors._();

  // -- Brand -----------------------------------------------------------------
  static const Color accent = Color(0xFF00D9F0); // neon cyan
  static const Color accentLight = Color(0xFF6BEBFA);
  static const Color accentDark = Color(0xFF0891B2);
  static const Color mint = Color(0xFF00E5C4);
  static const Color electric = Color(0xFF2E7DE0);

  /// The gradient used on primary actions, the mark and selection rails.
  static const List<Color> brandGradient = [electric, accent, mint];

  // -- Dark surfaces ---------------------------------------------------------
  static const Color background = Color(0xFF060A12);
  static const Color surface = Color(0xFF0C1524);
  static const Color surfaceElevated = Color(0xFF111C2E);
  static const Color surfaceLight = Color(0xFF16223A);
  static const Color border = Color(0xFF1B2839);
  static const Color borderStrong = Color(0xFF27384F);

  /// Backdrop of the terminal viewport.
  static const Color terminalBackground = Color(0xFF060A12);

  // -- Light surfaces --------------------------------------------------------
  static const Color surfaceLightMode = Color(0xFFF4F7FB);
  static const Color surfaceDarkMode = background;
  static const Color borderLight = Color(0xFFE2E8F0);

  // -- Status ----------------------------------------------------------------
  static const Color error = Color(0xFFF87171);
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);

  // -- Text ------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFE8EDF5);
  static const Color textSecondary = Color(0xFF8B9AB3);
  static const Color textTertiary = Color(0xFF5C6B85);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  /// Per-host accent colours, kept in the same cool-to-warm order the picker
  /// shows them in.
  static const List<Color> hostColors = [
    Color(0xFF00D9F0),
    Color(0xFF00E5C4),
    Color(0xFF2E7DE0),
    Color(0xFF8B7BF7),
    Color(0xFFFBBF24),
    Color(0xFFFB7185),
    Color(0xFF34D399),
    Color(0xFFF472B6),
  ];
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  AppRadius._();
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 22.0;
  static const double full = 999.0;
}

class AppDurations {
  AppDurations._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

/// Shared elevation and glow recipes.
class AppShadows {
  AppShadows._();

  static List<BoxShadow> card = const [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: -8,
    ),
  ];

  /// Coloured bloom used behind brand-coloured actions.
  static List<BoxShadow> glow(Color color, {double opacity = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 6),
          spreadRadius: -6,
        ),
      ];
}
