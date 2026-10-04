import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';

class ContactsPermissionDialog extends StatelessWidget {
  const ContactsPermissionDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => const ContactsPermissionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.cardSurface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Header
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.contacts_rounded,
                color: AppColors.navyPrimary,
                size: 26,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              'Contacts Permission Required',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.navyPrimary,
              ),
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              'MPM Connect needs access to your contacts to quickly add customers. You can grant this in your device settings.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onPrimaryContainer,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Cancel',
                    variant: AppButtonVariant.outlined,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Open Settings',
                    variant: AppButtonVariant.primary,
                    icon: Icons.settings_rounded,
                    onPressed: () async {
                      Navigator.of(context).pop(true);
                      await openAppSettings();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
