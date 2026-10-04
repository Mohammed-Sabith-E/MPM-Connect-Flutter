import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/dashboard/models/dashboard_metrics_model.dart';

/// Interactive Bottom Sheet for Account Notices & Overdue Alerts
class AccountNoticesSheet extends StatelessWidget {
  final List<OverdueCustomerItem> overdueNotices;

  const AccountNoticesSheet({
    super.key,
    required this.overdueNotices,
  });

  static Future<void> show(
    BuildContext context, {
    required List<OverdueCustomerItem> overdueNotices,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountNoticesSheet(overdueNotices: overdueNotices),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.canvasBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairlineBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sheet Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: overdueNotices.isNotEmpty
                            ? AppColors.crimsonContainer
                            : AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        overdueNotices.isNotEmpty
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        size: 20,
                        color: overdueNotices.isNotEmpty
                            ? AppColors.onCrimsonContainer
                            : AppColors.navyContainer,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Notices',
                          style: AppTypography.headlineSm(color: AppColors.navyContainer).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          overdueNotices.isNotEmpty
                              ? '${overdueNotices.length} Overdue Accounts Requiring Action'
                              : 'System Notices & Alerts',
                          style: AppTypography.bodySm(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.hairlineBorder),

          // Content List
          Flexible(
            child: overdueNotices.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(36),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.emeraldLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.verified_rounded, size: 30, color: AppColors.emeraldSuccess),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All Accounts In Good Standing',
                          style: AppTypography.headlineSm(color: AppColors.navyContainer).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'There are no overdue customer payments or pending ledger notices at this time.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySm(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shrinkWrap: true,
                    itemCount: overdueNotices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notice = overdueNotices[index];
                      final customer = notice.customer;
                      final dueSince = notice.oldestUnpaidDate;
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/customers/${customer.id}');
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.cardSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.crimsonDanger.withValues(alpha: 0.25)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(15, 43, 72, 0.03),
                                offset: Offset(0, 2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.crimsonContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.onCrimsonContainer),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceContainerLow,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            customer.customerCode,
                                            style: AppTypography.labelSm(color: AppColors.navyContainer).copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 9.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            customer.name,
                                            style: AppTypography.headlineSm(color: AppColors.navyContainer).copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${notice.daysOverdue} days overdue • Due since ${dueSince.day}/${dueSince.month}/${dueSince.year}',
                                      style: AppTypography.bodySm(color: AppColors.crimsonDanger).copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(customer.balance),
                                    style: AppTypography.currencyLedger(color: AppColors.crimsonDanger).copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'View Ledger ›',
                                    style: AppTypography.labelSm(color: AppColors.amberSecondary).copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
