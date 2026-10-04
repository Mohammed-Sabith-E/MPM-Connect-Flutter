import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/phone_normalizer.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/services/permission_service.dart';
import '../models/customer_model.dart';
import '../widgets/add_customer_options_sheet.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/mpm_app_header.dart';
import '../../../shared/widgets/mpm_bottom_nav.dart';
import '../../payments/screens/settlement_modal.dart';
import '../../../core/services/pdf_generator_service.dart';
import '../../../shared/screens/pdf_viewer_screen.dart';
import 'package:printing/printing.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  final _searchController = TextEditingController();
  String _filter = 'All'; // All, With Balance, Overdue, Zero Balance
  String _sortBy = 'name_asc'; // name_asc, balance_desc

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider(null));
    final user = ref.watch(currentUserProfileProvider).value;
    final role = user?.role ?? UserRole.salesman;
    final currentOrg = ref.watch(currentOrgProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: MpmAppHeader(
        title: 'MPM Connect',
        subtitle: 'Customers',
        organization: currentOrg,
        onNotificationTap: () {},
        onProfileTap: () => context.push('/settings'),
      ),
      floatingActionButton: PermissionService.canCreateCustomer(role)
          ? Container(
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
                tooltip: 'Add New Customer',
                onPressed: () => AddCustomerOptionsSheet.show(context),
                child: const Icon(Icons.person_add_rounded, size: 26),
              ),
            )
          : null,
      bottomNavigationBar: const MpmBottomNav(currentTab: MpmNavTab.customers),
      body: customersAsync.when(
        loading: () => const LoadingStateView(message: 'Loading customer directory...'),
        error: (err, stack) => ErrorStateView(
          message: err.toString(),
          onRetry: () => ref.invalidate(customersStreamProvider(null)),
        ),
        data: (allCustomers) {
          // Calculate total outstanding balance
          final totalOutstanding = allCustomers.fold<double>(
            0.0,
            (sum, c) => sum + (c.balance > 0 ? c.balance : 0),
          );
          final accountsWithBalance = allCustomers.where((c) => c.balance > 0).length;
          final overdueAccounts = allCustomers.where((c) => c.isOverdue).length;
          final zeroBalanceAccounts = allCustomers.where((c) => c.balance <= 0).length;

          // Apply local tab filter
          var displayList = allCustomers.where((c) {
            switch (_filter) {
              case 'With Balance':
                return c.balance > 0;
              case 'Overdue':
                return c.isOverdue;
              case 'Zero Balance':
                return c.balance <= 0;
              case 'All':
              default:
                return true;
            }
          }).toList();

          // Apply search query locally (keeps keyboard open without unmounting TextField)
          final queryClean = _searchController.text.toLowerCase().trim();
          if (queryClean.isNotEmpty) {
            final queryNormalized = PhoneNormalizer.normalize(queryClean);
            displayList = displayList.where((c) {
              final phoneNorm = c.normalizedPhone ?? PhoneNormalizer.normalize(c.phone);
              return c.name.toLowerCase().contains(queryClean) ||
                  c.phone.contains(queryClean) ||
                  (queryNormalized.isNotEmpty && phoneNorm.contains(queryNormalized)) ||
                  c.customerCode.toLowerCase().contains(queryClean);
            }).toList();
          }

          // Apply sorting
          if (_sortBy == 'balance_desc') {
            displayList.sort((a, b) => b.balance.compareTo(a.balance));
          } else if (_sortBy == 'name_asc') {
            displayList.sort((a, b) => a.name.compareTo(b.name));
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. Page Title & Action Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Customers',
                        style: AppTypography.headlineLg(color: AppColors.navyContainer).copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${allCustomers.length}',
                          style: AppTypography.labelMd(color: AppColors.navyContainer).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildHeaderIconButton(
                        icon: Icons.picture_as_pdf_outlined,
                        tooltip: 'Outstanding Report PDF',
                        onTap: () {
                          final settings = ref.read(businessSettingsProvider).value;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfViewerScreen(
                                title: 'Customer Outstanding Report',
                                filename: 'Customer_Outstanding_${DateTime.now().millisecondsSinceEpoch}.pdf',
                                pdfGenerator: () => PdfGeneratorService.generateOutstandingReport(
                                  customers: allCustomers,
                                  settings: settings,
                                  organization: currentOrg,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderIconButton(
                        icon: Icons.share_outlined,
                        tooltip: 'Share Outstanding Report',
                        onTap: () async {
                          final settings = ref.read(businessSettingsProvider).value;
                          final bytes = await PdfGeneratorService.generateOutstandingReport(
                            customers: allCustomers,
                            settings: settings,
                            organization: currentOrg,
                          );
                          await Printing.sharePdf(bytes: bytes, filename: 'Customer_Outstanding_${DateTime.now().millisecondsSinceEpoch}.pdf');
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildHeaderIconButton(
                        icon: Icons.tune_rounded,
                        tooltip: 'Filter',
                        onTap: () => _showFilterSheet(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Search Bar (Sovereign Theme)
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: AppTypography.bodyMd(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search customer name, phone, or code...',
                  hintStyle: AppTypography.bodyMd(color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navyContainer, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                          onPressed: () {
                            _searchController.clear();
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
              const SizedBox(height: 14),

              // 3. Receivables Pulse Banner (Deep Navy + Gold)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(15, 43, 72, 0.18),
                      offset: Offset(0, 4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.amberContainer,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'RECEIVABLES PULSE',
                              style: AppTypography.labelSm(color: AppColors.secondaryFixed).copyWith(
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$accountsWithBalance Accounts',
                            style: AppTypography.labelSm(color: AppColors.onPrimaryContainer).copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Customer Outstanding',
                          style: AppTypography.bodySm(color: AppColors.onPrimaryContainer),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(totalOutstanding),
                          style: AppTypography.currencyDisplay(color: AppColors.textOnDark).copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Filter Chips Row: All, With Balance, Overdue, Zero Balance
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'All (${allCustomers.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('With Balance', 'With Balance ($accountsWithBalance)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Overdue', 'Overdue ($overdueAccounts)'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Zero Balance', 'Zero Balance ($zeroBalanceAccounts)'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 5. Showing Count & Sort Trigger
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${displayList.length} accounts',
                    style: AppTypography.labelSm(color: AppColors.textSecondary),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _sortBy = _sortBy == 'balance_desc' ? 'name_asc' : 'balance_desc';
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.hairlineBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _sortBy == 'balance_desc' ? 'Sort: Highest Due' : 'Sort: Name (A-Z)',
                            style: AppTypography.labelSm(color: AppColors.navyContainer).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.swap_vert_rounded, size: 16, color: AppColors.navyContainer),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 6. Customers Cards List
              if (displayList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.hairlineBorder),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.person_search_rounded, size: 48, color: AppColors.outlineVariant),
                      const SizedBox(height: 12),
                      Text(
                        'No customers found matching filter.',
                        style: AppTypography.bodyMd(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              else
                ...displayList.map((customer) => _buildCustomerCard(context, customer)),

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.hairlineBorder),
        ),
        child: Icon(icon, size: 18, color: AppColors.navyContainer),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;

    return InkWell(
      onTap: () => setState(() => _filter = key),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyContainer : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.hairlineBorder,
          ),
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

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    final initials = customer.name.isNotEmpty
        ? customer.name.trim().split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
        : 'CU';

    final hasDue = customer.balance > 0;
    final isOverdue = customer.isOverdue;

    Color avatarBg = AppColors.surfaceContainer;
    Color avatarText = AppColors.navyContainer;
    if (isOverdue) {
      avatarBg = AppColors.crimsonContainer;
      avatarText = AppColors.onCrimsonContainer;
    } else if (hasDue) {
      avatarBg = AppColors.secondaryFixed;
      avatarText = AppColors.onSecondaryFixed;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairlineBorder),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 43, 72, 0.03),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push('/customers/${customer.id}'),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: AppTypography.headlineSm(color: avatarText).copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                      Row(
                        children: [
                          Text(
                            customer.customerCode,
                            style: AppTypography.bodySm(color: AppColors.navyContainer).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(' • ', style: TextStyle(color: AppColors.outlineVariant)),
                          Expanded(
                            child: Text(
                              customer.phoneNumber,
                              style: AppTypography.bodySm(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isOverdue)
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
                          'Overdue',
                          style: AppTypography.labelSm(color: AppColors.onCrimsonContainer).copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (hasDue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Due',
                      style: AppTypography.labelSm(color: AppColors.onSecondaryFixed).copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
                      'Outstanding Balance',
                      style: AppTypography.bodySm(color: AppColors.textSecondary).copyWith(fontSize: 11),
                    ),
                    Text(
                      CurrencyFormatter.format(customer.balance),
                      style: AppTypography.currencyLedger(
                        color: hasDue ? AppColors.crimsonDanger : AppColors.emeraldSuccess,
                      ).copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amberContainer,
                    foregroundColor: AppColors.onSecondaryContainer,
                    elevation: 0,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    SettlementModal.show(context, customer: customer);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Collect', style: AppTypography.labelSm(color: AppColors.onSecondaryContainer)),
                      const SizedBox(width: 3),
                      const Icon(Icons.chevron_right_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter & Sort Customers', style: AppTypography.headlineSm(color: AppColors.navyContainer)),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Highest Balance First'),
                  leading: const Icon(Icons.arrow_downward_rounded),
                  selected: _sortBy == 'balance_desc',
                  onTap: () {
                    setState(() => _sortBy = 'balance_desc');
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('Alphabetical (A-Z)'),
                  leading: const Icon(Icons.sort_by_alpha_rounded),
                  selected: _sortBy == 'name_asc',
                  onTap: () {
                    setState(() => _sortBy = 'name_asc');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
