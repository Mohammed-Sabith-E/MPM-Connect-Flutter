import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Sovereign Ledger Typography System for MPM Connect
/// Strictly matches DESIGN.md specifications
class AppTypography {
  AppTypography._();

  // Display & Headlines (Plus Jakarta Sans)
  static TextStyle displayLg({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.64,
        color: color,
      );

  static TextStyle headlineLg({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        letterSpacing: -0.36,
        color: color,
      );

  static TextStyle headlineMd({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle headlineSm({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 24 / 16,
        color: color,
      );

  // Currency Typography (with tabular figures for precise financial alignment)
  static TextStyle currencyDisplay({Color color = AppColors.textPrimary}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 36 / 28,
        letterSpacing: -0.56,
        color: color,
        fontFeatures: const [
          FontFeature.tabularFigures(),
          FontFeature.slashedZero(),
        ],
      );

  static TextStyle currencyLedger({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 22 / 16,
        color: color,
        fontFeatures: const [
          FontFeature.tabularFigures(),
          FontFeature.slashedZero(),
        ],
      );

  // Body & Labels (Inter)
  static TextStyle bodyLg({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: color,
      );

  static TextStyle bodyMd({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: color,
      );

  static TextStyle bodySm({Color color = AppColors.textMuted}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
        color: color,
      );

  static TextStyle labelLg({Color color = AppColors.textPrimary}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.14,
        color: color,
      );

  static TextStyle labelMd({Color color = AppColors.textSecondary}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.24,
        color: color,
      );

  static TextStyle labelSm({Color color = AppColors.textMuted}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 14 / 11,
        letterSpacing: 0.44,
        color: color,
      );

  // Standard Material 3 Getter Aliases
  static TextStyle get displayLarge => displayLg();
  static TextStyle get headlineLarge => headlineLg();
  static TextStyle get headlineMedium => headlineMd();
  static TextStyle get headlineSmall => headlineSm();
  static TextStyle get titleLarge => headlineMd();
  static TextStyle get titleMedium => headlineSm();
  static TextStyle get bodyLarge => bodyLg();
  static TextStyle get bodyMedium => bodyMd();
  static TextStyle get bodySmall => bodySm();
  static TextStyle get labelLarge => labelLg();
  static TextStyle get labelMedium => labelMd();
  static TextStyle get labelSmall => labelSm();
}
