import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../../../shared/widgets/app_button.dart';

class SelectPhoneDialog extends StatefulWidget {
  final String contactName;
  final List<String> phoneNumbers;
  final String? currentlySelected;

  const SelectPhoneDialog({
    super.key,
    required this.contactName,
    required this.phoneNumbers,
    this.currentlySelected,
  });

  static Future<String?> show(
    BuildContext context, {
    required String contactName,
    required List<String> phoneNumbers,
    String? currentlySelected,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SelectPhoneDialog(
        contactName: contactName,
        phoneNumbers: phoneNumbers,
        currentlySelected: currentlySelected,
      ),
    );
  }

  @override
  State<SelectPhoneDialog> createState() => _SelectPhoneDialogState();
}

class _SelectPhoneDialogState extends State<SelectPhoneDialog> {
  late String _selectedNumber;

  @override
  void initState() {
    super.initState();
    if (widget.currentlySelected != null &&
        widget.phoneNumbers.contains(widget.currentlySelected)) {
      _selectedNumber = widget.currentlySelected!;
    } else {
      _selectedNumber = widget.phoneNumbers.isNotEmpty ? widget.phoneNumbers.first : '';
    }
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
            // Title
            Text(
              'Select Phone Number',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.navyPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose the primary phone number for ${widget.contactName}:',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),

            // Number Options
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.phoneNumbers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final phone = widget.phoneNumbers[index];
                  final isSelected = phone == _selectedNumber;
                  final formatted = PhoneNormalizer.formatDisplay(phone);

                  return InkWell(
                    onTap: () => setState(() => _selectedNumber = phone),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryFixed.withValues(alpha: 0.4)
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.navyPrimary
                              : AppColors.hairlineBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: isSelected
                                ? AppColors.navyPrimary
                                : AppColors.onPrimaryContainer,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              formatted.isNotEmpty ? formatted : phone,
                              style: AppTypography.bodyLarge.copyWith(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: AppColors.navyPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Select',
                    variant: AppButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(_selectedNumber),
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
