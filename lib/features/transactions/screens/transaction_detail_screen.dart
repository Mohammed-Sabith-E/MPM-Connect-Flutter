import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../models/transaction_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/screens/pdf_viewer_screen.dart';
import 'package:printing/printing.dart';

class TransactionDetailScreen extends ConsumerWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txRepo = ref.watch(transactionRepositoryProvider);
    final customerRepo = ref.watch(customerRepositoryProvider);
    final settings = ref.watch(businessSettingsProvider).value;
    final currentOrg = ref.watch(currentOrgProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice Details', style: AppTypography.headlineSm(color: AppColors.navyContainer)),
        iconTheme: const IconThemeData(color: AppColors.navyContainer),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Invoice',
            onPressed: () async {
              final tx = await txRepo.getTransactionById(transactionId);
              if (tx == null) return;
              final customer = await customerRepo.getCustomerById(tx.customerId);
              final bytes = await PdfGeneratorService.generateTransactionInvoice(
                transaction: tx,
                customer: customer,
                settings: settings,
                organization: currentOrg,
              );
              await Printing.sharePdf(bytes: bytes, filename: '${tx.invoiceNumber}.pdf');
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Invoice PDF',
            onPressed: () async {
              final tx = await txRepo.getTransactionById(transactionId);
              if (tx == null) return;
              final customer = await customerRepo.getCustomerById(tx.customerId);

              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      title: 'Invoice ${tx.invoiceNumber}',
                      filename: '${tx.invoiceNumber}.pdf',
                      pdfGenerator: () => PdfGeneratorService.generateTransactionInvoice(
                        transaction: tx,
                        customer: customer,
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
      body: FutureBuilder<InvoiceTransaction?>(
        future: txRepo.getTransactionById(transactionId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingStateView(message: 'Loading invoice...');
          }
          final tx = snapshot.data;
          if (tx == null) {
            return const ErrorStateView(message: 'Invoice not found.');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card with Invoice # & Status
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.hairlineBorder),
                    boxShadow: const [AppColors.shadowLevel1],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.invoiceNumber,
                                style: AppTypography.headlineLg(color: AppColors.navyPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Date: ${DateFormatter.formatDate(tx.invoiceDate)}',
                                style: AppTypography.bodySm(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          StatusChip.fromPaymentStatus(tx.paymentStatus),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Customer Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Customer', style: AppTypography.labelSm(color: AppColors.textMuted)),
                                Text(tx.customerName, style: AppTypography.headlineSm(color: AppColors.navyDark)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Salesman Info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.badge_outlined, color: AppColors.textMuted, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Salesman', style: AppTypography.labelSm(color: AppColors.textMuted)),
                                Text(tx.salesmanName ?? 'Direct Store', style: AppTypography.headlineSm(color: AppColors.navyDark)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Financial Breakdown Ledger Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.hairlineBorder),
                    boxShadow: const [AppColors.shadowLevel1],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TRANSACTION BREAKDOWN', style: AppTypography.labelSm(color: AppColors.navyPrimary)),
                      const SizedBox(height: 16),

                      _buildRow('Previous Customer Balance', CurrencyFormatter.format(tx.previousBalance)),
                      const Divider(height: 20),

                      _buildRow('New Invoice Amount', CurrencyFormatter.format(tx.invoiceAmount), isBold: true),
                      const Divider(height: 20),

                      _buildRow(
                        'Payment Received (${tx.paymentMethod})',
                        CurrencyFormatter.format(tx.paymentReceived),
                        color: AppColors.emeraldSuccess,
                      ),
                      const Divider(height: 20, color: AppColors.navyPrimary, thickness: 1.5),

                      _buildRow(
                        'Net Customer Balance',
                        CurrencyFormatter.format(tx.newBalance),
                        isBold: true,
                        fontSize: 18,
                        color: tx.newBalance > 0 ? AppColors.crimsonDanger : AppColors.emeraldSuccess,
                      ),
                    ],
                  ),
                ),

                if (tx.notes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.navySoftTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notes', style: AppTypography.labelSm(color: AppColors.textMuted)),
                        const SizedBox(height: 4),
                        Text(tx.notes, style: AppTypography.bodyMd(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Print & Share PDF Actions
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: AppButton(
                        text: 'Preview PDF',
                        icon: Icons.picture_as_pdf_outlined,
                        variant: AppButtonVariant.outlined,
                        onPressed: () async {
                          final customer = await customerRepo.getCustomerById(tx.customerId);
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfViewerScreen(
                                  title: 'Invoice ${tx.invoiceNumber}',
                                  filename: '${tx.invoiceNumber}.pdf',
                                  pdfGenerator: () => PdfGeneratorService.generateTransactionInvoice(
                                    transaction: tx,
                                    customer: customer,
                                    settings: settings,
                                    organization: currentOrg,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: AppButton(
                        text: 'Share PDF',
                        icon: Icons.share_rounded,
                        variant: AppButtonVariant.accent,
                        onPressed: () async {
                          final customer = await customerRepo.getCustomerById(tx.customerId);
                          final bytes = await PdfGeneratorService.generateTransactionInvoice(
                            transaction: tx,
                            customer: customer,
                            settings: settings,
                            organization: currentOrg,
                          );
                          await Printing.sharePdf(bytes: bytes, filename: '${tx.invoiceNumber}.pdf');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, double fontSize = 15, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isBold
              ? AppTypography.headlineSm(color: AppColors.navyDark)
              : AppTypography.bodyMd(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: isBold
              ? AppTypography.currencyDisplay(color: color ?? AppColors.navyDark)
              : AppTypography.currencyLedger(color: color ?? AppColors.navyDark),
        ),
      ],
    );
  }
}
