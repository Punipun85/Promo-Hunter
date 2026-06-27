import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDeep = Color(0xFF059669);
  static const Color secondary = Color(0xFF2170E4);
  static const Color secondaryDeep = Color(0xFF0058BE);
  static const Color accent = Color(0xFFFACC15);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color surfaceHigh = Color(0xFFEFF4FF);
  static const Color surfaceHighest = Color(0xFFDCE9FF);
  static const Color outline = Color(0xFFBCCBB9);
  static const Color onSurface = Color(0xFF0B1C30);

  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
      primary: primaryDeep,
      onPrimary: Colors.white,
      primaryContainer: primary,
      secondary: secondaryDeep,
      onSecondary: Colors.white,
      secondaryContainer: secondary,
      tertiary: accent,
      surface: Colors.white,
      surfaceContainer: surfaceHigh,
      surfaceContainerHighest: surfaceHighest,
      outline: outline,
      error: const Color(0xFFBA1A1A),
    );

    final textTheme = base.textTheme.apply(
      fontFamily: 'PlusJakartaSans',
      bodyColor: onSurface,
      displayColor: onSurface,
    ).copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.64,
        color: onSurface,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.33,
        letterSpacing: -0.24,
        color: onSurface,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: onSurface,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: onSurface,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: onSurface,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: onSurface,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        color: const Color(0xFF64748B),
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontFamily: 'PlusJakartaSans',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF94A3B8),
        ),
        labelStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: secondary,
        backgroundColor: Colors.white,
        labelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryDeep,
          side: const BorderSide(color: Color(0xFFD7E3FF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerColor: const Color(0xFFE2E8F0),
    );
  }
}

