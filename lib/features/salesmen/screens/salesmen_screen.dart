import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/screens/pdf_viewer_screen.dart';
import 'package:printing/printing.dart';

import 'add_salesman_screen.dart';

class SalesmenScreen extends ConsumerStatefulWidget {
  const SalesmenScreen({super.key});

  @override
  ConsumerState<SalesmenScreen> createState() => _SalesmenScreenState();
}

class _SalesmenScreenState extends ConsumerState<SalesmenScreen> {
  @override
  Widget build(BuildContext context) {
    final salesmenAsync = ref.watch(salesmenStreamProvider);
    final settings = ref.watch(businessSettingsProvider).value;
    final currentOrg = ref.watch(currentOrgProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Salesmen Performance', style: AppTypography.headlineSm(color: AppColors.navyContainer)),
        iconTheme: const IconThemeData(color: AppColors.navyContainer),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Salesman Report',
            onPressed: () async {
              final salesmen = await ref.read(salesmanRepositoryProvider).streamSalesmen().first;
              final bytes = await PdfGeneratorService.generateSalesmanReport(
                salesmen: salesmen,
                settings: settings,
                organization: currentOrg,
              );
              await Printing.sharePdf(bytes: bytes, filename: 'Salesmen_${DateTime.now().millisecondsSinceEpoch}.pdf');
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Salesman Report PDF',
            onPressed: () async {
              final salesmen = await ref.read(salesmanRepositoryProvider).streamSalesmen().first;
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      title: 'Salesman Performance Report',
                      filename: 'Salesmen_${DateTime.now().millisecondsSinceEpoch}.pdf',
                      pdfGenerator: () => PdfGeneratorService.generateSalesmanReport(
                        salesmen: salesmen,
                        settings: settings,
                        organization: currentOrg,
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddSalesmanScreen()),
        ),
        child: const Icon(Icons.person_add_rounded),
      ),
      body: salesmenAsync.when(
        loading: () => const LoadingStateView(message: 'Loading salesmen...'),
        error: (err, stack) => ErrorStateView(message: err.toString()),
        data: (salesmen) {
          if (salesmen.isEmpty) {
            return EmptyStateView(
              icon: Icons.badge_outlined,
              title: 'No Salesmen Added',
              description: 'Add your sales representatives to track their individual sales and collections.',
              actionText: 'Add Salesman',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddSalesmanScreen()),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: salesmen.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final s = salesmen[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.hairlineBorder),
                  boxShadow: const [AppColors.shadowLevel1],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.navySoftTint,
                          child: const Icon(Icons.person_rounded, color: AppColors.navyPrimary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.name, style: AppTypography.headlineSm(color: AppColors.navyDark)),
                              Text(
                                '${s.phone}${s.email.isNotEmpty ? " • ${s.email}" : ""}',
                                style: AppTypography.bodySm(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Metrics Grid
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TOTAL SALES', style: AppTypography.labelSm(color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text(CurrencyFormatter.formatClean(s.totalSales), style: AppTypography.currencyLedger(color: AppColors.navyDark)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('COLLECTED', style: AppTypography.labelSm(color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text(CurrencyFormatter.formatClean(s.totalCollected), style: AppTypography.currencyLedger(color: AppColors.emeraldSuccess)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('OUTSTANDING', style: AppTypography.labelSm(color: AppColors.textMuted)),
                            const SizedBox(height: 2),
                            Text(CurrencyFormatter.formatClean(s.outstandingBalance), style: AppTypography.currencyLedger(color: AppColors.crimsonDanger)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
