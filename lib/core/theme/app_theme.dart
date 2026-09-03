import 'package:flutter/material.dart';
import 'package:konsol/core/constants/app_constants.dart';

class AppTheme {
  AppTheme._();

  static TextStyle _sans({
    double size = 16,
    FontWeight weight = FontWeight.normal,
    Color? color,
    double tracking = -0.2,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: tracking,
      height: 1.35,
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) => TextTheme(
        displaySmall: _sans(size: 32, weight: FontWeight.w800, color: primary, tracking: -1),
        headlineLarge: _sans(size: 28, weight: FontWeight.w700, color: primary, tracking: -0.8),
        headlineMedium: _sans(size: 22, weight: FontWeight.w700, color: primary, tracking: -0.6),
        headlineSmall: _sans(size: 18, weight: FontWeight.w600, color: primary),
        titleLarge: _sans(size: 20, weight: FontWeight.w600, color: primary, tracking: -0.4),
        titleMedium: _sans(size: 16, weight: FontWeight.w600, color: primary),
        titleSmall: _sans(size: 14, weight: FontWeight.w600, color: primary),
        bodyLarge: _sans(size: 16, color: primary),
        bodyMedium: _sans(size: 14, color: primary),
        bodySmall: _sans(size: 13, color: secondary),
        labelLarge: _sans(size: 14, weight: FontWeight.w600, color: primary),
        labelMedium: _sans(size: 12, weight: FontWeight.w600, color: secondary),
        labelSmall: _sans(size: 11, weight: FontWeight.w500, color: secondary, tracking: 0.4),
      );

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color hint,
  }) {
    OutlineInputBorder outline(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c, width: w),
        );

    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      border: outline(border),
      enabledBorder: outline(border),
      focusedBorder: outline(AppColors.accent, 1.5),
      errorBorder: outline(AppColors.error),
      focusedErrorBorder: outline(AppColors.error, 1.5),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      hintStyle: _sans(size: 14, color: hint),
      labelStyle: _sans(size: 14, color: hint),
      floatingLabelStyle: _sans(size: 13, weight: FontWeight.w600, color: AppColors.accent),
      prefixIconColor: hint,
      suffixIconColor: hint,
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final text = _textTheme(AppColors.textPrimary, AppColors.textSecondary);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: Color(0xFF04212B),
        primaryContainer: AppColors.accentDark,
        secondary: AppColors.mint,
        onSecondary: Color(0xFF04231E),
        tertiary: AppColors.electric,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceElevated,
        outline: AppColors.border,
        error: AppColors.error,
        onError: Color(0xFF2B0A0A),
      ),
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _sans(size: 18, weight: FontWeight.w700, color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
        actionsIconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.surface,
        border: AppColors.border,
        hint: AppColors.textTertiary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: const Color(0xFF04212B),
          disabledBackgroundColor: AppColors.surfaceLight,
          disabledForegroundColor: AppColors.textTertiary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: _sans(size: 15, weight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          textStyle: _sans(size: 14, weight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.borderStrong),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: _sans(size: 14, weight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Color(0xFF04212B),
        elevation: 0,
        highlightElevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        textColor: AppColors.textPrimary,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        showDragHandle: true,
        dragHandleColor: AppColors.borderStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: _sans(size: 18, weight: FontWeight.w700, color: AppColors.textPrimary),
        contentTextStyle: _sans(size: 14, color: AppColors.textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceLight,
        side: const BorderSide(color: AppColors.border),
        labelStyle: _sans(size: 12, weight: FontWeight.w600, color: AppColors.textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? const Color(0xFF04212B) : AppColors.textTertiary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? AppColors.accent : AppColors.surfaceLight,
        ),
        trackOutlineColor: WidgetStateProperty.all(AppColors.border),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.surfaceLight,
        thumbColor: AppColors.accent,
        overlayColor: Color(0x2200D9F0),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: _sans(size: 14, color: AppColors.textPrimary),
        actionTextColor: AppColors.accent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.surfaceLight,
      ),
      splashColor: AppColors.accent.withValues(alpha: 0.08),
      highlightColor: AppColors.accent.withValues(alpha: 0.05),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final text = _textTheme(AppColors.textPrimaryLight, AppColors.textSecondaryLight);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.surfaceLightMode,
      colorScheme: const ColorScheme.light(
        primary: AppColors.accentDark,
        onPrimary: Colors.white,
        secondary: AppColors.electric,
        surface: Colors.white,
        onSurface: AppColors.textPrimaryLight,
        outline: AppColors.borderLight,
        error: Color(0xFFDC2626),
      ),
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLightMode,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _sans(size: 18, weight: FontWeight.w700, color: AppColors.textPrimaryLight),
        iconTheme: const IconThemeData(color: AppColors.textSecondaryLight, size: 22),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: Colors.white,
        border: AppColors.borderLight,
        hint: AppColors.textSecondaryLight,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: _sans(size: 15, weight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimaryLight,
        contentTextStyle: _sans(size: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

TextStyle monospace({double size = 14, FontWeight weight = FontWeight.normal, Color? color}) {
  return TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.5,
  );
}
