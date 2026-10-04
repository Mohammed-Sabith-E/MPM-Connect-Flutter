import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import 'status_chip.dart';

class LedgerItemTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit; // true if payment/inflow (+), false if invoice/outflow (-)
  final String? status;
  final IconData leadingIcon;
  final VoidCallback? onTap;

  const LedgerItemTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    this.status,
    this.leadingIcon = Icons.receipt_long_rounded,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amountColor = isCredit ? AppColors.emeraldSuccess : AppColors.navyDark;
    final prefix = isCredit ? '+ ' : '- ';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.hairlineBorder, width: 1),
          ),
          child: Row(
            children: [
              // Circular 40px glyph container in #F0F4F8
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.navySoftTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  leadingIcon,
                  size: 20,
                  color: isCredit ? AppColors.emeraldSuccess : AppColors.navyPrimary,
                ),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: AppTypography.headlineSm(color: AppColors.navyDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySm(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Right-Aligned Currency Ledger & Status Chip
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$prefix${CurrencyFormatter.formatClean(amount)}',
                    style: AppTypography.currencyLedger(color: amountColor),
                  ),
                  if (status != null) ...[
                    const SizedBox(height: 4),
                    StatusChip.fromPaymentStatus(status!),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
