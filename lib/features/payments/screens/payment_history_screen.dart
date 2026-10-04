import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../models/payment_model.dart';
import '../../../shared/widgets/ledger_item_tile.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/screens/pdf_viewer_screen.dart';
import 'package:printing/printing.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  String _selectedMethod = 'All';

  @override
  Widget build(BuildContext context) {
    final paymentRepo = ref.watch(paymentRepositoryProvider);
    final settings = ref.watch(businessSettingsProvider).value;
    final currentOrg = ref.watch(currentOrgProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Payments & Collections', style: AppTypography.headlineSm(color: AppColors.navyContainer)),
        iconTheme: const IconThemeData(color: AppColors.navyContainer),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Collection Report',
            onPressed: () async {
              final payments = await paymentRepo.streamPayments(
                paymentMethod: _selectedMethod == 'All' ? null : _selectedMethod,
              ).first;
              final bytes = await PdfGeneratorService.generatePaymentCollectionReport(
                payments: payments,
                settings: settings,
                organization: currentOrg,
              );
              await Printing.sharePdf(bytes: bytes, filename: 'Collections_${DateTime.now().millisecondsSinceEpoch}.pdf');
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Collection Report PDF',
            onPressed: () async {
              final payments = await paymentRepo.streamPayments(
                paymentMethod: _selectedMethod == 'All' ? null : _selectedMethod,
              ).first;

              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      title: 'Payment Collection Report',
                      filename: 'Collections_${DateTime.now().millisecondsSinceEpoch}.pdf',
                      pdfGenerator: () => PdfGeneratorService.generatePaymentCollectionReport(
                        payments: payments,
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
      body: Column(
        children: [
          // Filter Chips by Payment Method
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.cardSurface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Cash', 'UPI', 'Bank', 'Other'].map((method) {
                  final isSelected = _selectedMethod == method;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(method),
                      selected: isSelected,
                      selectedColor: AppColors.navyPrimary,
                      labelStyle: AppTypography.labelSm(
                        color: isSelected ? AppColors.textOnDark : AppColors.textPrimary,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedMethod = method);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Payment List Stream
          Expanded(
            child: StreamBuilder<List<PaymentRecord>>(
              stream: paymentRepo.streamPayments(
                paymentMethod: _selectedMethod == 'All' ? null : _selectedMethod,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingStateView(message: 'Loading payment history...');
                }
                if (snapshot.hasError) {
                  return ErrorStateView(message: snapshot.error.toString());
                }

                final payments = snapshot.data ?? [];
                if (payments.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.payments_outlined,
                    title: 'No Payments Found',
                    description: 'No settlement records found for the selected payment method.',
                  );
                }

                final totalCollections = payments.fold(0.0, (sum, p) => sum + p.amount);

                return Column(
                  children: [
                    // Total Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: AppColors.surfaceContainerLow,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TOTAL COLLECTED', style: AppTypography.labelSm(color: AppColors.textMuted)),
                          Text(
                            CurrencyFormatter.format(totalCollections),
                            style: AppTypography.currencyLedger(color: AppColors.emeraldSuccess),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: payments.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final p = payments[index];
                          return LedgerItemTile(
                            title: p.customerName,
                            subtitle: '${DateFormatter.formatDate(p.paymentDate)} • Method: ${p.paymentMethod} • By: ${p.receivedByName ?? "Staff"}',
                            amount: p.amount,
                            isCredit: true,
                            leadingIcon: Icons.payments_rounded,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
