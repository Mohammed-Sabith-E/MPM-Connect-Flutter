import 'package:flutter/material.dart';

/// Sovereign Ledger Color System for MPM Connect
/// Strictly matches DESIGN.md and Stitch specifications
class AppColors {
  AppColors._();

  // Primary Deep Navy
  static const Color navyPrimary = Color(0xFF00162D);
  static const Color navyDark = Color(0xFF0A1E33);
  static const Color navyContainer = Color(0xFF0F2B48);
  static const Color navySoftTint = Color(0xFFEFF4FF);
  static const Color onPrimaryContainer = Color(0xFF7A93B5);
  static const Color primaryFixed = Color(0xFFD2E4FF);
  static const Color primaryFixedDim = Color(0xFFAFC8ED);
  static const Color onPrimaryFixed = Color(0xFF001C37);
  static const Color onPrimaryFixedVariant = Color(0xFF2F4867);

  // Secondary Amber / Gold
  static const Color amberSecondary = Color(0xFF904D00);
  static const Color amberPrimary = Color(0xFFD97706);
  static const Color amberAccent = Color(0xFFF59E0B);
  static const Color amberContainer = Color(0xFFFE932C);
  static const Color amberLight = Color(0xFFFEF3C7);
  static const Color onSecondaryContainer = Color(0xFF663500);
  static const Color secondaryFixed = Color(0xFFFFDCC3);
  static const Color secondaryFixedDim = Color(0xFFFFB77D);
  static const Color onSecondaryFixed = Color(0xFF2F1500);
  static const Color onSecondaryFixedVariant = Color(0xFF6E3900);

  // Semantic Success / Received Emerald
  static const Color emeraldSuccess = Color(0xFF059669);
  static const Color emeraldAccent = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFFECFDF5);
  static const Color tertiaryDark = Color(0xFF001A0F);
  static const Color tertiaryContainer = Color(0xFF003120);
  static const Color onTertiaryContainer = Color(0xFF26A476);
  static const Color tertiaryFixed = Color(0xFF85F8C4);
  static const Color tertiaryFixedDim = Color(0xFF68DBA9);
  static const Color onTertiaryFixed = Color(0xFF002114);
  static const Color onTertiaryFixedVariant = Color(0xFF005137);

  // Semantic Danger / Overdue Crimson
  static const Color crimsonDanger = Color(0xFFDC2626);
  static const Color crimsonAccent = Color(0xFFEF4444);
  static const Color crimsonContainer = Color(0xFFFFDAD6);
  static const Color crimsonLight = Color(0xFFFEF2F2);
  static const Color onCrimsonContainer = Color(0xFF93000A);

  // Neutrals & Surfaces (Sovereign Ledger M3)
  static const Color canvasBackground = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceDim = Color(0xFFCBDBF5);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);
  static const Color hairlineBorder = Color(0xFFE2E8F0);
  static const Color outline = Color(0xFF74777E);
  static const Color outlineVariant = Color(0xFFC4C6CE);
  static const Color surfaceTint = Color(0xFF476080);

  // Text colors
  static const Color textPrimary = Color(0xFF0B1C30);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color textSecondary = Color(0xFF43474D);
  static const Color onSurfaceVariant = Color(0xFF43474D);
  static const Color textMuted = Color(0xFF64748B);
  static const Color slateNeutral = Color(0xFF64748B);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Dark Theme Palette
  static const Color darkCanvas = Color(0xFF070E17);
  static const Color darkSurface = Color(0xFF0F1A28);
  static const Color darkSurfaceContainer = Color(0xFF172436);
  static const Color darkBorder = Color(0xFF253448);
  static const Color darkTextPrimary = Color(0xFFF0F4F8);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Ambient Navy Shadows
  static const BoxShadow shadowLevel1 = BoxShadow(
    color: Color.fromRGBO(15, 43, 72, 0.05),
    offset: Offset(0, 1),
    blurRadius: 3,
  );
  static const BoxShadow shadowLevel1Ambient = BoxShadow(
    color: Color.fromRGBO(15, 43, 72, 0.03),
    offset: Offset(0, 4),
    blurRadius: 12,
  );

  static const BoxShadow shadowLevel2 = BoxShadow(
    color: Color.fromRGBO(15, 43, 72, 0.08),
    offset: Offset(0, 4),
    blurRadius: 8,
  );
  static const BoxShadow shadowLevel2Ambient = BoxShadow(
    color: Color.fromRGBO(15, 43, 72, 0.06),
    offset: Offset(0, 12),
    blurRadius: 24,
  );

  static const BoxShadow cardShadow = BoxShadow(
    color: Color.fromRGBO(15, 43, 72, 0.04),
    offset: Offset(0, 2),
    blurRadius: 8,
  );
}
