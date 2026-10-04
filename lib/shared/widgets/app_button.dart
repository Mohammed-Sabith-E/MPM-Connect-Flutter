import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum AppButtonVariant {
  primary,
  accent, // Amber for high-value financial actions
  outlined,
  text,
}

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide side = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.accent:
        bg = AppColors.amberPrimary;
        fg = AppColors.textOnDark;
        break;
      case AppButtonVariant.outlined:
        bg = AppColors.cardSurface;
        fg = AppColors.navyPrimary;
        side = const BorderSide(color: AppColors.hairlineBorder, width: 1.5);
        break;
      case AppButtonVariant.text:
        bg = Colors.transparent;
        fg = AppColors.navyPrimary;
      case AppButtonVariant.primary:
        bg = AppColors.navyPrimary;
        fg = AppColors.textOnDark;
        break;
    }

    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(text, style: AppTypography.labelLg(color: fg)),
            ],
          );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          side: side,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}
