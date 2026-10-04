import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../models/customer_model.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/mpm_app_header.dart';
import '../../../shared/widgets/ledger_item_tile.dart';
import '../../payments/screens/settlement_modal.dart';
import '../../../shared/screens/pdf_viewer_screen.dart';
import 'package:printing/printing.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  ConsumerState<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends ConsumerState<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerRepo = ref.watch(customerRepositoryProvider);
    final txRepo = ref.watch(transactionRepositoryProvider);
    final paymentRepo = ref.watch(paymentRepositoryProvider);

    final currentOrg = ref.watch(currentOrgProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: MpmAppHeader(
        title: 'Customer Detail',
        showBackButton: true,
        organization: currentOrg,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.navyContainer),
            tooltip: 'Edit Customer',
            onPressed: () => context.push('/customers/edit/${widget.customerId}'),
          ),
        ],
      ),
      body: StreamBuilder<List<Customer>>(
        stream: customerRepo.streamCustomers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingStateView(message: 'Loading customer details...');
          }

          final customers = snapshot.data ?? [];
          final matches = customers.where((c) => c.id == widget.customerId);
          if (matches.isEmpty) {
            return const ErrorStateView(message: 'Customer profile not found.');
          }

          final customer = matches.first;
          final isOverdue = customer.isOverdue;
          final hasDue = customer.balance > 0;
          final creditLimit = customer.creditLimit > 0 ? customer.creditLimit : 100000.0;
          final utilization = (customer.balance / creditLimit * 100).clamp(0, 100).toStringAsFixed(0);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // 1. Customer Profile Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.hairlineBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(15, 43, 72, 0.04),
                      offset: Offset(0, 2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.storefront_rounded,
                              color: AppColors.navyContainer,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customer.name,
                                style: AppTypography.headlineMd(color: AppColors.navyContainer).copyWith(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      customer.customerCode,
                                      style: AppTypography.labelSm(color: AppColors.textSecondary),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Contact info strip
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone_in_talk_rounded, size: 16, color: AppColors.navyContainer),
                              const SizedBox(width: 8),
                              Text(
                                customer.phoneNumber,
                                style: AppTypography.bodySm(color: AppColors.textPrimary).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Text(' • ', style: TextStyle(color: AppColors.outlineVariant)),
                              Expanded(
                                child: Text(
                                  customer.contactPerson.isNotEmpty ? customer.contactPerson : 'Primary Contact',
                                  style: AppTypography.bodySm(color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (customer.address.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.navyContainer),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    customer.address,
                                    style: AppTypography.bodySm(color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 4-Action Touch Strip
                    Row(
                      children: [
                        _buildProfileActionButton(
                          icon: Icons.call_rounded,
                          label: 'Call',
                          color: AppColors.navyContainer,
                          onTap: () {
                            AppToast.info('Calling ${customer.phoneNumber}');
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildProfileActionButton(
                          icon: Icons.share_rounded,
                          label: 'Share PDF',
                          color: AppColors.tertiaryContainer,
                          iconColor: AppColors.tertiaryFixed,
                          onTap: () async {
                            final transactions = await txRepo.streamTransactions(customerId: widget.customerId).first;
                            final payments = await paymentRepo.streamPayments(customerId: widget.customerId).first;
                            final settings = ref.read(businessSettingsProvider).value;
                            final bytes = await PdfGeneratorService.generateCustomerStatement(
                              customer: customer,
                              transactions: transactions,
                              payments: payments,
                              settings: settings,
                              organization: currentOrg,
                            );
                            await Printing.sharePdf(bytes: bytes, filename: 'Statement_${customer.customerCode}.pdf');
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildProfileActionButton(
                          icon: Icons.picture_as_pdf_rounded,
                          label: 'Statement',
                          color: AppColors.amberSecondary,
                          onTap: () async {
                            final transactions = await txRepo.streamTransactions(customerId: widget.customerId).first;
                            final payments = await paymentRepo.streamPayments(customerId: widget.customerId).first;
                            final settings = ref.read(businessSettingsProvider).value;

                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PdfViewerScreen(
                                    title: '${customer.name} - Statement',
                                    filename: 'Statement_${customer.customerCode}.pdf',
                                    pdfGenerator: () => PdfGeneratorService.generateCustomerStatement(
                                      customer: customer,
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Large Hero Financial Ledger Card (Deep Navy + Gold)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.navyContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(15, 43, 72, 0.22),
                      offset: Offset(0, 6),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          customer.balance < 0 ? 'ADVANCE BALANCE (CREDIT)' : 'AMOUNT TO GET (OUTSTANDING)',
                          style: AppTypography.labelSm(color: AppColors.onPrimaryContainer).copyWith(
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.crimsonContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.onCrimsonContainer),
                                const SizedBox(width: 4),
                                Text(
                                  'Overdue Account',
                                  style: AppTypography.labelSm(color: AppColors.onCrimsonContainer).copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (customer.balance < 0) ...[
                          Text(
                            '-',
                            style: AppTypography.displayLg(color: AppColors.amberContainer).copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 2),
                        ],
                        Text(
                          '₹',
                          style: AppTypography.displayLg(color: AppColors.amberContainer).copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          CurrencyFormatter.formatWithoutSymbol(customer.balance.abs()),
                          style: AppTypography.displayLg(color: AppColors.amberContainer).copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Credit limit: ${CurrencyFormatter.format(creditLimit)} • $utilization% utilized',
                      style: AppTypography.bodySm(color: AppColors.onPrimaryContainer),
                    ),
                    const SizedBox(height: 16),

                    // 3-Column Breakdown Bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.navyPrimary.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'INVOICED',
                                  style: AppTypography.labelSm(color: AppColors.onPrimaryContainer).copyWith(fontSize: 9.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(customer.totalInvoiced),
                                  style: AppTypography.headlineSm(color: AppColors.textOnDark).copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Lifetime Total',
                                  style: AppTypography.bodySm(color: AppColors.onPrimaryContainer).copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 32, color: Colors.white12),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PAID',
                                  style: AppTypography.labelSm(color: AppColors.tertiaryFixedDim).copyWith(fontSize: 9.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  CurrencyFormatter.format(customer.totalPaid),
                                  style: AppTypography.headlineSm(color: AppColors.tertiaryFixed).copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Received Total',
                                  style: AppTypography.bodySm(color: AppColors.tertiaryFixedDim).copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 32, color: Colors.white12),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'STATUS',
                                  style: AppTypography.labelSm(color: AppColors.secondaryFixed).copyWith(fontSize: 9.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasDue ? 'Open Dues' : (customer.balance < 0 ? 'Advance' : 'Cleared'),
                                  style: AppTypography.headlineSm(color: AppColors.secondaryFixed).copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  hasDue ? 'Unsettled' : (customer.balance < 0 ? 'Credit Balance' : 'Zero Balance'),
                                  style: AppTypography.bodySm(color: AppColors.secondaryFixedDim).copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Quick Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('New Invoice'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyContainer,
                        foregroundColor: AppColors.textOnDark,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.labelMd(color: AppColors.textOnDark).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => context.push('/transactions/new?customerId=${customer.id}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.payments_rounded, size: 18),
                      label: const Text('Collect Payment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amberContainer,
                        foregroundColor: AppColors.onSecondaryContainer,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        textStyle: AppTypography.labelMd(color: AppColors.onSecondaryContainer).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () => SettlementModal.show(context, customer: customer),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Ledger Activity Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.navyContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTypography.labelMd(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: AppTypography.labelMd(color: AppColors.textSecondary),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Invoices & Bills'),
                    Tab(text: 'Payment Receipts'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5. Stream Content based on Tab
              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Invoices List
                    StreamBuilder(
                      stream: txRepo.streamTransactions(customerId: customer.id),
                      builder: (context, txSnapshot) {
                        if (txSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final transactions = txSnapshot.data ?? [];
                        if (transactions.isEmpty) {
                          return Center(
                            child: Text(
                              'No invoices generated for this customer.',
                              style: AppTypography.bodyMd(color: AppColors.textMuted),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: transactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            return LedgerItemTile(
                              title: tx.invoiceNumber,
                              subtitle: '${DateFormatter.formatDate(tx.invoiceDate)} • By ${tx.salesmanName}',
                              amount: tx.invoiceAmount,
                              isCredit: false,
                              status: tx.paymentStatus,
                              onTap: () => context.push('/transactions/${tx.id}'),
                            );
                          },
                        );
                      },
                    ),

                    // Payments List
                    StreamBuilder(
                      stream: paymentRepo.streamPayments(customerId: customer.id),
                      builder: (context, paySnapshot) {
                        if (paySnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final payments = paySnapshot.data ?? [];
                        if (payments.isEmpty) {
                          return Center(
                            child: Text(
                              'No payment receipts recorded yet.',
                              style: AppTypography.bodyMd(color: AppColors.textMuted),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: payments.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final payment = payments[index];
                            return LedgerItemTile(
                              title: 'Receipt #${payment.receiptNumber}',
                              subtitle: '${DateFormatter.formatDate(payment.paymentDate)} • ${payment.paymentMethod}',
                              amount: payment.amountPaid,
                              isCredit: true,
                              status: 'PAID',
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Icon(icon, size: 20, color: iconColor ?? color),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.labelSm(color: AppColors.navyContainer).copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
