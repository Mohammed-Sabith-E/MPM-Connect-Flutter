import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_toast.dart';
import 'contacts_permission_dialog.dart';

class AddCustomerOptionsSheet extends ConsumerWidget {
  const AddCustomerOptionsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddCustomerOptionsSheet(),
    );
  }

  Future<bool> _requestContactsPermission(BuildContext context) async {
    final status = await Permission.contacts.status;

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        await ContactsPermissionDialog.show(context);
      }
      return false;
    }

    final requested = await Permission.contacts.request();
    if (requested.isGranted) return true;

    if (context.mounted) {
      await ContactsPermissionDialog.show(context);
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProfileProvider).value;
    final role = currentUser?.role ?? UserRole.salesman;
    final canBulkImport = PermissionService.canBulkImportCustomers(role);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(15, 43, 72, 0.16),
            offset: Offset(0, -4),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title and Subtitle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Customer',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose how you want to add customer records',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.onPrimaryContainer),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Option 1: Add Manually
              _buildOptionTile(
                context,
                icon: Icons.person_add_rounded,
                iconColor: AppColors.navyPrimary,
                iconBgColor: AppColors.primaryFixed,
                title: 'Add Manually',
                subtitle: 'Fill in customer details manually from scratch',
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/customers/add');
                },
              ),
              const SizedBox(height: 12),

              // Option 2: From Phone Contacts (Single)
              _buildOptionTile(
                context,
                icon: Icons.contact_phone_rounded,
                iconColor: AppColors.amberSecondary,
                iconBgColor: AppColors.amberLight,
                title: 'From Phone Contacts',
                subtitle: 'Pick one contact and auto-populate the form',
                onTap: () async {
                  final granted = await _requestContactsPermission(context);
                  if (!granted || !context.mounted) return;

                  Navigator.of(context).pop();
                  context.push(
                    '/customers/import-picker',
                    extra: false, // isMultiSelect = false
                  );
                },
              ),
              const SizedBox(height: 12),

              // Option 3: Import Multiple Contacts (Bulk)
              _buildOptionTile(
                context,
                icon: Icons.group_add_rounded,
                iconColor: canBulkImport ? AppColors.emeraldSuccess : AppColors.onPrimaryContainer,
                iconBgColor: canBulkImport ? AppColors.emeraldLight : AppColors.surfaceContainerLow,
                title: 'Import Multiple Contacts',
                subtitle: canBulkImport
                    ? 'Select multiple phone contacts and bulk import'
                    : 'Requires Admin or Salesman permission',
                enabled: canBulkImport,
                onTap: canBulkImport
                    ? () async {
                        final granted = await _requestContactsPermission(context);
                        if (!granted || !context.mounted) return;

                        Navigator.of(context).pop();
                        context.push(
                          '/customers/import-picker',
                          extra: true, // isMultiSelect = true
                        );
                      }
                    : () {
                        AppToast.info('Cashiers cannot perform bulk imports.');
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badgeText,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: enabled ? AppColors.canvasBackground : AppColors.surfaceContainerLow.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairlineBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: enabled ? AppColors.navyPrimary : AppColors.onPrimaryContainer,
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.navyPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
