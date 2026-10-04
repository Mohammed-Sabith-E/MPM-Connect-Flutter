import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/mpm_app_header.dart';
import '../../../shared/widgets/mpm_bottom_nav.dart';
import '../../../shared/widgets/account_notices_sheet.dart';
import '../../payments/screens/settlement_modal.dart';
import '../../transactions/models/transaction_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedTxFilter = 'all'; // all, paid, partial, credit

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final currentOrg = ref.watch(currentOrgProvider);
    final userProfileAsync = ref.watch(currentUserProfileProvider);

    if (userProfileAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.canvasBackground,
        body: LoadingStateView(message: 'Verifying organization access...'),
      );
    }

    if (currentOrg == null) {
      return Scaffold(
        backgroundColor: AppColors.canvasBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.domain_disabled_rounded, size: 64, color: AppColors.crimsonDanger),
                const SizedBox(height: 20),
                Text(
                  'Your account is not assigned to an organization.',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSm(color: AppColors.navyDark),
                ),
                const SizedBox(height: 12),
                Text(
                  'Please contact your system administrator to assign your account to an organization.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMd(color: AppColors.textMuted),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final metricsAsync = ref.watch(dashboardMetricsStreamProvider);
    final appUser = userProfileAsync.value;

    final userName = (appUser?.name.isNotEmpty == true)
        ? appUser!.name.trim()
        : 'Admin';

    final overdueNotices = metricsAsync.value?.overdueCustomers ?? [];
    final overdueCount = overdueNotices.length;

    final formattedDate = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: MpmAppHeader(
        title: 'MPM Connect',
        subtitle: 'Dashboard',
        organization: ref.watch(currentOrgProvider),
        notificationCount: overdueCount,
        onNotificationTap: () {
          AccountNoticesSheet.show(context, overdueNotices: overdueNotices);
        },
        onProfileTap: () => context.push('/settings'),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Container(
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
            tooltip: 'Create New Invoice',
            onPressed: () => context.push('/transactions/new'),
            child: const Icon(Icons.post_add_rounded, size: 28),
          ),
        ),
      ),
      bottomNavigationBar: const MpmBottomNav(currentTab: MpmNavTab.dashboard),
      body: metricsAsync.when(
        loading: () => const LoadingStateView(message: 'Loading financial summary...'),
        error: (err, stack) => ErrorStateView(
          message: err.toString(),
          onRetry: () => ref.invalidate(dashboardMetricsStreamProvider),
        ),
        data: (metrics) {
          final overdueList = metrics.overdueCustomers;

          // Filter transactions based on selection
          final filteredTxs = metrics.recentTransactions.where((tx) {
            if (_selectedTxFilter == 'all') return true;
            return tx.paymentStatus.toLowerCase().trim() == _selectedTxFilter;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(dashboardMetricsStreamProvider),
            color: AppColors.navyPrimary,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              children: [
                // 1. Executive Greeting & Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate.toUpperCase(),
                            style: AppTypography.labelSm(color: AppColors.textSecondary).copyWith(
                              letterSpacing: 0.8,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_getGreeting()}, $userName',
                            style: AppTypography.headlineLg(color: AppColors.navyContainer).copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.tertiaryFixedDim,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Online Sync',
                            style: AppTypography.labelSm(color: AppColors.navyContainer).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 2. Quick Action Shortcut Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPillButton(
                        icon: Icons.add_rounded,
                        label: 'New Invoice',
                        isPrimary: true,
                        onTap: () => context.push('/transactions/new'),
                      ),
                      const SizedBox(width: 8),
                      _buildPillButton(
                        icon: Icons.payments_outlined,
                        iconColor: AppColors.amberContainer,
                        label: 'Record Payment',
                        onTap: () => context.push('/customers'),
                      ),
                      const SizedBox(width: 8),
                      _buildPillButton(
                        icon: Icons.share_outlined,
                        label: 'Statement',
                        onTap: () => context.push('/reports'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. 2x2 Key Financial Metrics Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.28,
                  children: [
                    // Card 1: Today's Sales (Anchor Card in Deep Navy)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.navyContainer,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(15, 43, 72, 0.18),
                            offset: Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "TODAY'S SALES",
                                style: AppTypography.labelSm(color: AppColors.surfaceContainerHighest).copyWith(
                                  letterSpacing: 0.8,
                                  fontSize: 10.5,
                                ),
                              ),
                              const Icon(Icons.trending_up_rounded, color: AppColors.amberContainer, size: 20),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '₹',
                                style: AppTypography.headlineSm(color: AppColors.textOnDark).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  CurrencyFormatter.formatWithoutSymbol(metrics.todaySales),
                                  style: AppTypography.currencyDisplay(color: AppColors.textOnDark).copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${metrics.recentTransactions.length} orders',
                                style: AppTypography.bodySm(color: AppColors.surfaceContainerHighest).copyWith(fontSize: 11),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '+12.4%',
                                  style: AppTypography.labelSm(color: AppColors.tertiaryFixed).copyWith(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Card 2: Received
                    _buildMetricCard(
                      label: 'RECEIVED',
                      amount: metrics.amountReceivedToday,
                      amountColor: AppColors.navyContainer,
                      icon: Icons.arrow_downward_rounded,
                      iconBg: AppColors.surfaceContainerLow,
                      iconColor: AppColors.onTertiaryContainer,
                      bottomText: "Today's cash/UPI",
                      bottomWidget: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppColors.tertiaryFixedDim,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // Card 3: Credit Given
                    _buildMetricCard(
                      label: 'CREDIT GIVEN',
                      amount: metrics.creditAmountToday,
                      amountColor: AppColors.amberSecondary,
                      icon: Icons.pending_actions_rounded,
                      iconBg: AppColors.secondaryFixed.withValues(alpha: 0.5),
                      iconColor: AppColors.amberSecondary,
                      bottomText: 'Credit invoices',
                      bottomWidget: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryFixed,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Today',
                          style: AppTypography.labelSm(color: AppColors.onSecondaryFixed).copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Card 4: To Collect
                    _buildMetricCard(
                      label: 'TO COLLECT',
                      amount: metrics.totalAmountToGet,
                      amountColor: AppColors.textPrimary,
                      icon: Icons.priority_high_rounded,
                      iconBg: AppColors.crimsonLight,
                      iconColor: AppColors.crimsonDanger,
                      bottomText: 'Outstanding',
                      bottomWidget: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.crimsonContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${overdueList.length} Dues',
                          style: AppTypography.labelSm(color: AppColors.onCrimsonContainer).copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. Overdue Accounts Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Overdue Accounts',
                          style: AppTypography.headlineMd(color: AppColors.navyContainer).copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.crimsonContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '7+ Days',
                            style: AppTypography.labelSm(color: AppColors.onCrimsonContainer).copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push('/customers'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'View All (${overdueList.length})',
                        style: AppTypography.labelSm(color: AppColors.amberContainer).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (overdueList.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.hairlineBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.emeraldSuccess, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No customer accounts overdue past 7 days.',
                            style: AppTypography.bodyMd(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...overdueList.take(3).map((item) => _buildOverdueCustomerCard(item)),

                const SizedBox(height: 20),

                // 5. Recent Transactions Header & Status Filter Pills
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: AppTypography.headlineMd(color: AppColors.navyContainer).copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/transactions'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'All (${metrics.recentTransactions.length})',
                        style: AppTypography.labelSm(color: AppColors.navyContainer).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Filter Pills: All, Paid, Partial, Credit
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTxFilterChip('all', 'All (${metrics.recentTransactions.length})'),
                      const SizedBox(width: 8),
                      _buildTxFilterChip('paid', 'Paid'),
                      const SizedBox(width: 8),
                      _buildTxFilterChip('partial', 'Partial'),
                      const SizedBox(width: 8),
                      _buildTxFilterChip('credit', 'Credit'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Transactions List
                if (filteredTxs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.hairlineBorder),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'No transactions match the selected filter.',
                      style: AppTypography.bodyMd(color: AppColors.textMuted),
                    ),
                  )
                else
                  ...filteredTxs.take(6).map((tx) => _buildTransactionCard(tx)),

                const SizedBox(height: 28),

                // Developer Branding Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.hairlineBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/zobotic_logo.png',
                          height: 18,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Engineered by Zobotic Innovations • www.zobotic.in',
                          style: AppTypography.labelSm(color: AppColors.textSecondary).copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    Color? iconColor,
    bool isPrimary = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.navyContainer : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isPrimary ? Colors.transparent : AppColors.hairlineBorder,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 43, 72, 0.04),
              offset: Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary
                  ? Colors.white
                  : (iconColor ?? AppColors.textSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMd(
                color: isPrimary ? Colors.white : AppColors.navyContainer,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required double amount,
    required Color amountColor,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String bottomText,
    required Widget bottomWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.labelSm(color: AppColors.textSecondary).copyWith(
                  letterSpacing: 0.8,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Icon(icon, color: iconColor, size: 16)),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹',
                style: AppTypography.headlineSm(color: amountColor).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  CurrencyFormatter.formatWithoutSymbol(amount),
                  style: AppTypography.currencyDisplay(color: amountColor).copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bottomText,
                style: AppTypography.bodySm(color: AppColors.textSecondary).copyWith(fontSize: 11),
              ),
              bottomWidget,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueCustomerCard(dynamic item) {
    final customer = item.customer;
    final initials = customer.name.isNotEmpty
        ? customer.name.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'CU';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.crimsonContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTypography.headlineSm(color: AppColors.onCrimsonContainer).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
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
                      style: AppTypography.headlineSm(color: AppColors.navyContainer).copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${customer.customerCode} • ${customer.phoneNumber}',
                      style: AppTypography.bodySm(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.crimsonContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.crimsonDanger,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Overdue: ${item.daysOverdue}d',
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
          const Divider(height: 1, color: AppColors.hairlineBorder),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance Due',
                    style: AppTypography.bodySm(color: AppColors.textSecondary).copyWith(fontSize: 11),
                  ),
                  Text(
                    CurrencyFormatter.format(customer.balance),
                    style: AppTypography.currencyLedger(color: AppColors.crimsonDanger).copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amberContainer,
                      foregroundColor: AppColors.onSecondaryContainer,
                      elevation: 0,
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      SettlementModal.show(context, customer: customer);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Collect', style: AppTypography.labelSm(color: AppColors.onSecondaryContainer)),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTxFilterChip(String status, String label) {
    final isSelected = _selectedTxFilter == status;

    return InkWell(
      onTap: () => setState(() => _selectedTxFilter = status),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyContainer : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(15, 43, 72, 0.15),
                    offset: Offset(0, 2),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.labelMd(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ).copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    final isPaid = tx.paymentStatus.toLowerCase() == 'paid';
    final isPartial = tx.paymentStatus.toLowerCase() == 'partial';

    IconData iconData = Icons.receipt_long_rounded;
    Color iconBg = AppColors.surfaceContainer;
    Color iconColor = AppColors.navyContainer;
    Color statusBg = AppColors.surfaceContainer;
    Color statusText = AppColors.navyContainer;
    String statusLabel = 'Paid: ${CurrencyFormatter.format(tx.paymentReceived)}';
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
      microLabel = 'Due in 15d';
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
