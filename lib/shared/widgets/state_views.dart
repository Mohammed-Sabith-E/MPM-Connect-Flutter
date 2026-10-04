import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'app_button.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.navySoftTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.navyPrimary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.headlineSm(color: AppColors.navyDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTypography.bodyMd(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 20),
              AppButton(
                text: actionText!,
                onPressed: onAction,
                width: 200,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.crimsonLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded, size: 36, color: AppColors.crimsonDanger),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTypography.headlineSm(color: AppColors.navyDark),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMd(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              AppButton(
                text: 'Try Again',
                onPressed: onRetry,
                width: 160,
                variant: AppButtonVariant.outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingStateView extends StatelessWidget {
  final String? message;

  const LoadingStateView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.navyPrimary),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: AppTypography.bodyMd(color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}
