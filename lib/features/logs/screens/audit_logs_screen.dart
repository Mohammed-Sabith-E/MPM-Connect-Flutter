import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/state_views.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  String _selectedModule = 'All';

  @override
  Widget build(BuildContext context) {
    final auditLogsAsync = ref.watch(auditLogsStreamProvider(_selectedModule == 'All' ? null : _selectedModule));

    return Scaffold(
      appBar: AppBar(
        title: Text('Audit & Security Logs', style: AppTypography.headlineSm(color: AppColors.navyContainer)),
        iconTheme: const IconThemeData(color: AppColors.navyContainer),
      ),
      body: Column(
        children: [
          // Filter Chips by Module
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.cardSurface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Auth', 'Customers', 'Transactions', 'Payments', 'Users', 'Salesmen'].map((m) {
                  final isSelected = _selectedModule == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(m),
                      selected: isSelected,
                      selectedColor: AppColors.navyPrimary,
                      labelStyle: AppTypography.labelSm(
                        color: isSelected ? AppColors.textOnDark : AppColors.textPrimary,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedModule = m);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Audit Stream List
          Expanded(
            child: auditLogsAsync.when(
              loading: () => const LoadingStateView(message: 'Loading security logs...'),
              error: (err, stack) => ErrorStateView(message: err.toString()),
              data: (logs) {
                if (logs.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.history_edu_outlined,
                    title: 'No Audit Records',
                    description: 'No system events have been logged for this module yet.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.hairlineBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.navySoftTint,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(log.module.toUpperCase(), style: AppTypography.labelSm(color: AppColors.navyPrimary)),
                              ),
                              Text(
                                DateFormatter.formatDateTime(log.timestamp),
                                style: AppTypography.bodySm(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(log.description, style: AppTypography.bodyMd(color: AppColors.navyDark)),
                          const SizedBox(height: 6),
                          Text('Actor: ${log.userName} (${log.action})', style: AppTypography.bodySm(color: AppColors.textMuted)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
