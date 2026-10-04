import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../../../shared/screens/pdf_viewer_screen.dart';

class ReportsHubScreen extends ConsumerWidget {
  const ReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerRepo = ref.watch(customerRepositoryProvider);
    final txRepo = ref.watch(transactionRepositoryProvider);
    final paymentRepo = ref.watch(paymentRepositoryProvider);
    final salesmanRepo = ref.watch(salesmanRepositoryProvider);
    final settings = ref.watch(businessSettingsProvider).value;
    final currentOrg = ref.watch(currentOrgProvider);

    final reportItems = [
      {
        'title': 'Customer Outstanding Report',
        'subtitle': 'Detailed analysis of all pending receivables, balances, and overdue accounts.',
        'icon': Icons.account_balance_wallet_outlined,
        'action': () async {
          final customers = await customerRepo.streamCustomers().first;
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(
                  title: 'Customer Outstanding Report',
                  filename: 'Customer_Outstanding.pdf',
                  pdfGenerator: () => PdfGeneratorService.generateOutstandingReport(
                    customers: customers,
                    settings: settings,
                    organization: currentOrg,
                  ),
                ),
              ),
            );
          }
        },
        'share': () async {
          final customers = await customerRepo.streamCustomers().first;
          final bytes = await PdfGeneratorService.generateOutstandingReport(
            customers: customers,
            settings: settings,
            organization: currentOrg,
          );
          await Printing.sharePdf(bytes: bytes, filename: 'Customer_Outstanding.pdf');
        },
      },
      {
        'title': 'All Transactions Report',
        'subtitle': 'Comprehensive ledger of all sales invoices, payment splits, and balances.',
        'icon': Icons.receipt_long_outlined,
        'action': () async {
          final transactions = await txRepo.streamTransactions().first;
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(
                  title: 'All Transactions Report',
                  filename: 'All_Transactions.pdf',
                  pdfGenerator: () => PdfGeneratorService.generateAllTransactionsReport(
                    transactions: transactions,
                    settings: settings,
                    organization: currentOrg,
                  ),
                ),
              ),
            );
          }
        },
        'share': () async {
          final transactions = await txRepo.streamTransactions().first;
          final bytes = await PdfGeneratorService.generateAllTransactionsReport(
            transactions: transactions,
            settings: settings,
            organization: currentOrg,
          );
          await Printing.sharePdf(bytes: bytes, filename: 'All_Transactions.pdf');
        },
      },
      {
        'title': 'Daily Sales & Collections',
        'subtitle': 'Today’s financial breakdown of invoices, cash down-payments, and settlements.',
        'icon': Icons.today_outlined,
        'action': () async {
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day);
          final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

          final transactions = await txRepo.streamTransactions(startDate: start, endDate: end).first;
          final payments = await paymentRepo.streamPayments(startDate: start, endDate: end).first;

          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(
                  title: 'Daily Sales Report',
                  filename: 'Daily_Sales.pdf',
                  pdfGenerator: () => PdfGeneratorService.generateDailySalesReport(
                    reportDate: now,
                    transactions: transactions,
                    payments: payments,
                    settings: settings,
                    organization: currentOrg,
                  ),
                ),
              ),
            );
          }
        },
        'share': () async {
          final now = DateTime.now();
          final start = DateTime(now.year, now.month, now.day);
          final end = DateTime(now.year, now.month, now.day, 23, 59, 59);

          final transactions = await txRepo.streamTransactions(startDate: start, endDate: end).first;
          final payments = await paymentRepo.streamPayments(startDate: start, endDate: end).first;

          final bytes = await PdfGeneratorService.generateDailySalesReport(
            reportDate: now,
            transactions: transactions,
            payments: payments,
            settings: settings,
            organization: currentOrg,
          );
          await Printing.sharePdf(bytes: bytes, filename: 'Daily_Sales.pdf');
        },
      },
      {
        'title': 'Payment Collection Report',
        'subtitle': 'Chronological audit of all cash, UPI, and bank receipts collected.',
        'icon': Icons.payments_outlined,
        'action': () async {
          final payments = await paymentRepo.streamPayments().first;
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(
                  title: 'Payment Collection Report',
                  filename: 'Payment_Collections.pdf',
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
        'share': () async {
          final payments = await paymentRepo.streamPayments().first;
          final bytes = await PdfGeneratorService.generatePaymentCollectionReport(
            payments: payments,
            settings: settings,
            organization: currentOrg,
          );
          await Printing.sharePdf(bytes: bytes, filename: 'Payment_Collections.pdf');
        },
      },
      {
        'title': 'Salesman Performance Report',
        'subtitle': 'Total sales generated, amounts collected, and pending client balances per agent.',
        'icon': Icons.badge_outlined,
        'action': () async {
          final salesmen = await salesmanRepo.streamSalesmen().first;
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(
                  title: 'Salesman Performance Report',
                  filename: 'Salesman_Performance.pdf',
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
        'share': () async {
          final salesmen = await salesmanRepo.streamSalesmen().first;
          final bytes = await PdfGeneratorService.generateSalesmanReport(
            salesmen: salesmen,
            settings: settings,
            organization: currentOrg,
          );
          await Printing.sharePdf(bytes: bytes, filename: 'Salesman_Performance.pdf');
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Reports Hub', style: AppTypography.headlineSm(color: AppColors.navyContainer)),
        iconTheme: const IconThemeData(color: AppColors.navyContainer),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: reportItems.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = reportItems[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item['action'] as VoidCallback,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.hairlineBorder),
                  boxShadow: const [AppColors.shadowLevel1],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.navySoftTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item['icon'] as IconData, color: AppColors.navyPrimary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'] as String, style: AppTypography.headlineSm(color: AppColors.navyDark)),
                          const SizedBox(height: 4),
                          Text(item['subtitle'] as String, style: AppTypography.bodySm(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, color: AppColors.navyContainer, size: 20),
                      tooltip: 'Direct Share PDF',
                      onPressed: item['share'] as VoidCallback,
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
