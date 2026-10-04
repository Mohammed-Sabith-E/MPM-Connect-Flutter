import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';

class MetricSummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;
  final Color? amountColor;
  final VoidCallback? onTap;

  const MetricSummaryCard({
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    this.iconColor = AppColors.navyPrimary,
    this.subtitle,
    this.amountColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairlineBorder, width: 1),
            boxShadow: const [
              AppColors.shadowLevel1,
              AppColors.shadowLevel1Ambient,
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: AppTypography.labelSm(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.navySoftTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  CurrencyFormatter.formatClean(amount),
                  style: AppTypography.currencyDisplay(
                    color: amountColor ?? AppColors.navyDark,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: AppTypography.bodySm(color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
