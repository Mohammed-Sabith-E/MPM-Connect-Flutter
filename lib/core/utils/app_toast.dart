import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppToast {
  AppToast._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Shows a success toast with an emerald green accent and checkmark
  static void success(String message, [BuildContext? context]) {
    _show(
      message: message,
      backgroundColor: AppColors.emeraldSuccess,
      icon: Icons.check_circle_rounded,
      textColor: Colors.white,
      context: context,
    );
  }

  /// Shows an error toast with a crimson red accent and alert icon
  static void error(String message, [BuildContext? context]) {
    _show(
      message: message,
      backgroundColor: AppColors.crimsonDanger,
      icon: Icons.error_outline_rounded,
      textColor: Colors.white,
      context: context,
    );
  }

  /// Shows an informational toast with a navy container accent
  static void info(String message, [BuildContext? context]) {
    _show(
      message: message,
      backgroundColor: AppColors.navyContainer,
      icon: Icons.info_outline_rounded,
      textColor: Colors.white,
      context: context,
    );
  }

  static void _show({
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Color textColor,
    BuildContext? context,
  }) {
    ScaffoldMessengerState? state;
    if (context != null && context.mounted) {
      state = ScaffoldMessenger.maybeOf(context);
    }
    state ??= messengerKey.currentState;
    if (state == null) return;

    state.hideCurrentSnackBar();

    state.showSnackBar(
      SnackBar(
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: backgroundColor,
        duration: const Duration(milliseconds: 2500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMd(color: textColor).copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
