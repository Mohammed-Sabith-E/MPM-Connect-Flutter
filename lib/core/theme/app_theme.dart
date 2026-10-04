import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Sovereign Ledger Material 3 Theme Configuration
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.navyPrimary,
        onPrimary: AppColors.textOnDark,
        primaryContainer: AppColors.navyContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.amberSecondary,
        onSecondary: AppColors.textOnDark,
        secondaryContainer: AppColors.amberLight,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.emeraldSuccess,
        onTertiary: AppColors.textOnDark,
        tertiaryContainer: AppColors.emeraldLight,
        onTertiaryContainer: AppColors.tertiaryContainer,
        error: AppColors.crimsonDanger,
        onError: AppColors.textOnDark,
        errorContainer: AppColors.crimsonContainer,
        onErrorContainer: AppColors.onCrimsonContainer,
        surface: AppColors.canvasBackground,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.outline,
        outlineVariant: AppColors.hairlineBorder,
      ),
      scaffoldBackgroundColor: AppColors.canvasBackground,
      fontFamily: GoogleFonts.inter().fontFamily,
      textTheme: baseTextTheme.copyWith(
        displayLarge: AppTypography.displayLg(),
        headlineLarge: AppTypography.headlineLg(),
        headlineMedium: AppTypography.headlineMd(),
        headlineSmall: AppTypography.headlineSm(),
        bodyLarge: AppTypography.bodyLg(),
        bodyMedium: AppTypography.bodyMd(),
        bodySmall: AppTypography.bodySm(),
        labelLarge: AppTypography.labelLg(),
        labelMedium: AppTypography.labelMd(),
        labelSmall: AppTypography.labelSm(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvasBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineSm(color: AppColors.navyContainer),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.canvasBackground,
        indicatorColor: AppColors.secondaryFixed.withValues(alpha: 0.5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSm(color: AppColors.navyContainer).copyWith(fontWeight: FontWeight.bold);
          }
          return AppTypography.labelSm(color: AppColors.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.navyContainer, size: 22);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navyPrimary,
          foregroundColor: AppColors.textOnDark,
          minimumSize: const Size(double.infinity, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.labelLg(color: AppColors.textOnDark),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navyPrimary,
          minimumSize: const Size(double.infinity, 48),
          side: const BorderSide(color: AppColors.hairlineBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.labelLg(color: AppColors.navyPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navyPrimary,
          textStyle: AppTypography.labelLg(color: AppColors.navyPrimary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hairlineBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hairlineBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.navyPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.crimsonDanger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.crimsonDanger, width: 2),
        ),
        labelStyle: AppTypography.bodyMd(color: AppColors.textMuted),
        hintStyle: AppTypography.bodyMd(color: AppColors.textMuted),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),
      cardTheme: CardTheme(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.hairlineBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairlineBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFFAFC8ED),
        onPrimary: Color(0xFF001C37),
        primaryContainer: AppColors.navyContainer,
        onPrimaryContainer: AppColors.navySoftTint,
        secondary: AppColors.amberAccent,
        onSecondary: Color(0xFF2F1500),
        secondaryContainer: Color(0xFF6E3900),
        onSecondaryContainer: AppColors.amberLight,
        tertiary: AppColors.emeraldAccent,
        onTertiary: Color(0xFF002114),
        tertiaryContainer: Color(0xFF005137),
        onTertiaryContainer: AppColors.emeraldLight,
        error: AppColors.crimsonAccent,
        onError: Color(0xFF490003),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: AppColors.crimsonContainer,
        surface: AppColors.darkCanvas,
        onSurface: AppColors.darkTextPrimary,
        onSurfaceVariant: AppColors.darkTextSecondary,
        outline: AppColors.slateNeutral,
        outlineVariant: AppColors.darkBorder,
      ),
      scaffoldBackgroundColor: AppColors.darkCanvas,
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
