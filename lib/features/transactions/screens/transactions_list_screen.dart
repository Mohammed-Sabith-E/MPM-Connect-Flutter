import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_pagination_provider.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/screens/pdf_viewer_screen.dart';
import 'package:printing/printing.dart';
import '../../../shared/widgets/mpm_app_header.dart';
import '../../../shared/widgets/mpm_bottom_nav.dart';
import '../../../shared/widgets/searchable_customer_picker.dart';

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends ConsumerState<TransactionsListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      // Trigger load more when 200px before bottom
      if (currentScroll >= maxScroll - 200) {
        ref.read(transactionPaginationProvider.notifier).loadMore();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paginationState = ref.watch(transactionPaginationProvider);
    final paginationNotifier = ref.read(transactionPaginationProvider.notifier);
    final txRepo = ref.watch(transactionRepositoryProvider);
    final settings = ref.watch(businessSettingsProvider).value;
    final currentOrg = ref.watch(currentOrgProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: MpmAppHeader(
        title: 'MPM Connect',
        subtitle: 'Transactions',
        organization: currentOrg,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.navyContainer),
            tooltip: 'Share Transactions PDF',
            onPressed: () async {
              final transactions = await txRepo.streamTransactions(
                customerId: paginationState.selectedCustomer?.id,
                paymentStatus: paginationState.paymentStatus == 'All' ? null : paginationState.paymentStatus,
                searchQuery: _searchController.text,
                sortBy: paginationState.sortBy,
              ).first;
              final bytes = await PdfGeneratorService.generateAllTransactionsReport(
                transactions: transactions,
                settings: settings,
                organization: currentOrg,
              );
              await Printing.sharePdf(bytes: bytes, filename: 'Transactions_${DateTime.now().millisecondsSinceEpoch}.pdf');
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.navyContainer),
            tooltip: 'Export Transactions PDF',
            onPressed: () async {
              final transactions = await txRepo.streamTransactions(
                customerId: paginationState.selectedCustomer?.id,
                paymentStatus: paginationState.paymentStatus == 'All' ? null : paginationState.paymentStatus,
                searchQuery: _searchController.text,
                sortBy: paginationState.sortBy,
              ).first;

              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      title: 'Transactions Report',
                      filename: 'Transactions_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
          ),
        ],
      ),
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(254, 147, 44, 0.35),
              offset: Offset(0, 4),
              blurRadius: 14,
            ),
          ],
          border: Border.all(color: AppColors.canvasBackground, width: 3),
        ),
        child: FloatingActionButton(
          backgroundColor: AppColors.amberContainer,
          foregroundColor: AppColors.textOnDark,
          elevation: 0,
          shape: const CircleBorder(),
          tooltip: 'New Sale / Invoice',
          onPressed: () async {
            await context.push('/transactions/new');
            // Refresh paginated list after returning from new invoice
            if (mounted) {
              paginationNotifier.refresh();
            }
          },
          child: const Icon(Icons.post_add_rounded, size: 28),
        ),
      ),
      bottomNavigationBar: const MpmBottomNav(currentTab: MpmNavTab.transactions),
      body: Column(
        children: [
          // Search & Filter Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.canvasBackground,
              border: Border(bottom: BorderSide(color: AppColors.hairlineBorder)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {});
                    paginationNotifier.onSearchChanged(value);
                  },
                  style: AppTypography.bodyMd(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search invoice #, customer, salesman...',
                    hintStyle: AppTypography.bodyMd(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navyContainer, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              paginationNotifier.onSearchChanged('');
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.hairlineBorder, width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.hairlineBorder, width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.navyPrimary, width: 1.8),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Customer Filter Picker Button
                      InkWell(
                        onTap: () async {
                          final customers = await ref.read(customerRepositoryProvider).streamCustomers().first;
                          if (context.mounted) {
                            final picked = await SearchableCustomerPicker.show(
                              context,
                              customers: customers,
                              selectedCustomer: paginationState.selectedCustomer,
                            );
                            if (picked != null) {
                              paginationNotifier.setCustomer(picked);
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: paginationState.selectedCustomer != null
                                ? AppColors.amberContainer.withValues(alpha: 0.15)
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: paginationState.selectedCustomer != null
                                  ? AppColors.amberSecondary
                                  : AppColors.hairlineBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 15,
                                color: paginationState.selectedCustomer != null
                                    ? AppColors.amberSecondary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                paginationState.selectedCustomer != null
                                    ? paginationState.selectedCustomer!.name
                                    : 'Customer',
                                style: AppTypography.labelSm(
                                  color: paginationState.selectedCustomer != null
                                      ? AppColors.navyContainer
                                      : AppColors.textSecondary,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (paginationState.selectedCustomer != null) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => paginationNotifier.setCustomer(null),
                                  child: const Icon(Icons.close_rounded, size: 14, color: AppColors.navyContainer),
                                ),
                              ] else ...[
                                const SizedBox(width: 3),
                                const Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppColors.textSecondary),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Status Tabs
                      ...['All', 'paid', 'partial', 'credit'].map((status) {
                        final isSelected = paginationState.paymentStatus.toLowerCase() == status.toLowerCase();
                        final label = status == 'All' ? 'All' : status[0].toUpperCase() + status.substring(1);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => paginationNotifier.setPaymentStatus(status),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.navyContainer : AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                label,
                                style: AppTypography.labelSm(
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ).copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Transactions List with Cursor Pagination & Pull-to-refresh
          Expanded(
            child: Builder(
              builder: (context) {
                if (paginationState.isLoading && paginationState.transactions.isEmpty) {
                  return const LoadingStateView(message: 'Loading ledger transactions...');
                }

                if (paginationState.errorMessage != null && paginationState.transactions.isEmpty) {
                  return ErrorStateView(
                    message: paginationState.errorMessage!,
                    onRetry: () => paginationNotifier.loadInitial(),
                  );
                }

                final cleanQuery = _searchController.text.toLowerCase().trim();
                var transactions = paginationState.transactions;
                if (cleanQuery.isNotEmpty) {
                  transactions = transactions.where((t) {
                    final invMatch = t.invoiceNumber.toLowerCase().contains(cleanQuery);
                    final custMatch = t.customerName.toLowerCase().contains(cleanQuery);
                    final salesmanMatch = t.salesmanName?.toLowerCase().contains(cleanQuery) ?? false;
                    final notesMatch = t.notes.toLowerCase().contains(cleanQuery);
                    return invMatch || custMatch || salesmanMatch || notesMatch;
                  }).toList();
                }

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.outlineVariant),
                        const SizedBox(height: 12),
                        Text(
                          cleanQuery.isNotEmpty
                              ? 'No transactions matching "$cleanQuery"'
                              : 'No transactions found.',
                          style: AppTypography.bodyMd(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => paginationNotifier.refresh(),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Refresh'),
                          style: TextButton.styleFrom(foregroundColor: AppColors.amberSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final showFooter = paginationState.isLoadingMore || (!paginationState.hasMore && transactions.isNotEmpty);

                return RefreshIndicator(
                  color: AppColors.amberSecondary,
                  backgroundColor: AppColors.cardSurface,
                  onRefresh: () => paginationNotifier.refresh(),
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: transactions.length + (showFooter ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < transactions.length) {
                        final tx = transactions[index];
                        return _buildTxCard(context, tx);
                      }

                      // Infinite scroll footer
                      if (paginationState.isLoadingMore) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.amberSecondary,
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Loading older transactions...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // End of list reached
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Text(
                          'All transactions loaded (${transactions.length} total)',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxCard(BuildContext context, TransactionModel tx) {
    final isPaid = tx.paymentStatus.toLowerCase() == 'paid';
    final isPartial = tx.paymentStatus.toLowerCase() == 'partial';

    IconData iconData = Icons.receipt_rounded;
    Color iconBg = AppColors.surfaceContainer;
    Color iconColor = AppColors.navyContainer;
    Color statusBg = AppColors.surfaceContainer;
    Color statusText = AppColors.navyContainer;
    String statusLabel = 'Paid: ${CurrencyFormatter.format(tx.invoiceAmount)}';
    String microLabel = 'Full Settle';
    Color microColor = AppColors.onTertiaryContainer;

    if (isPaid) {
      iconData = Icons.store_rounded;
      iconBg = AppColors.surfaceContainer;
      iconColor = AppColors.navyContainer;
      statusBg = AppColors.surfaceContainer;
      statusText = AppColors.navyContainer;
      statusLabel = 'Paid: ${CurrencyFormatter.format(tx.invoiceAmount)}';
      microLabel = 'Full Settle';
      microColor = AppColors.onTertiaryContainer;
    } else if (isPartial) {
      iconData = Icons.receipt_rounded;
      iconBg = AppColors.secondaryFixed.withValues(alpha: 0.4);
      iconColor = AppColors.amberSecondary;
      statusBg = AppColors.secondaryFixed;
      statusText = AppColors.onSecondaryFixed;
      statusLabel = 'Bal: ${CurrencyFormatter.format(tx.invoiceAmount - tx.paymentReceived)}';
      microLabel = 'Paid: ${CurrencyFormatter.format(tx.paymentReceived)}';
      microColor = AppColors.textSecondary;
    } else {
      iconData = Icons.credit_card_off_rounded;
      iconBg = AppColors.crimsonContainer.withValues(alpha: 0.6);
      iconColor = AppColors.crimsonDanger;
      statusBg = AppColors.crimsonContainer;
      statusText = AppColors.onCrimsonContainer;
      statusLabel = 'Credit: ₹0 Paid';
      microLabel = 'Due';
      microColor = AppColors.crimsonDanger;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairlineBorder),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 43, 72, 0.03),
            offset: Offset(0, 1),
            blurRadius: 6,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/transactions/${tx.id}'),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.customerName,
                    style: AppTypography.headlineSm(color: AppColors.navyContainer).copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        tx.invoiceNumber,
                        style: AppTypography.bodySm(color: AppColors.navyContainer).copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const Text(' • ', style: TextStyle(color: AppColors.outlineVariant)),
                      Expanded(
                        child: Text(
                          tx.salesmanName ?? 'Direct',
                          style: AppTypography.bodySm(color: AppColors.textSecondary).copyWith(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    DateFormatter.formatDateTime(tx.invoiceDate),
                    style: AppTypography.bodySm(color: AppColors.textMuted).copyWith(fontSize: 10.5),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(tx.invoiceAmount),
                  style: AppTypography.currencyLedger(
                    color: isPaid ? AppColors.textPrimary : AppColors.crimsonDanger,
                  ).copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTypography.labelSm(color: statusText).copyWith(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  microLabel,
                  style: AppTypography.labelSm(color: microColor).copyWith(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
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
