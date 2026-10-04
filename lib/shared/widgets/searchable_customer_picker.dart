import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/customers/models/customer_model.dart';

class SearchableCustomerPicker extends StatefulWidget {
  final List<Customer> customers;
  final Customer? selectedCustomer;
  final ValueChanged<Customer> onCustomerSelected;
  final VoidCallback? onAddNewCustomer;

  const SearchableCustomerPicker({
    super.key,
    required this.customers,
    this.selectedCustomer,
    required this.onCustomerSelected,
    this.onAddNewCustomer,
  });

  static Future<Customer?> show(
    BuildContext context, {
    required List<Customer> customers,
    Customer? selectedCustomer,
    VoidCallback? onAddNewCustomer,
  }) {
    return showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(15, 43, 72, 0.16),
                  offset: Offset(0, -4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: SearchableCustomerPicker(
              customers: customers,
              selectedCustomer: selectedCustomer,
              onCustomerSelected: (customer) => Navigator.of(ctx).pop(customer),
              onAddNewCustomer: onAddNewCustomer != null
                  ? () {
                      Navigator.of(ctx).pop();
                      onAddNewCustomer();
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }

  @override
  State<SearchableCustomerPicker> createState() => _SearchableCustomerPickerState();
}

class _SearchableCustomerPickerState extends State<SearchableCustomerPicker> {
  final _searchController = TextEditingController();
  String _filter = 'All'; // All, With Due, Overdue

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> get _filteredCustomers {
    final query = _searchController.text.toLowerCase().trim();

    return widget.customers.where((c) {
      // Filter by tab
      if (_filter == 'With Due' && c.balance <= 0) return false;
      if (_filter == 'Overdue' && !c.isOverdue) return false;

      // Filter by search query
      if (query.isEmpty) return true;
      return c.name.toLowerCase().contains(query) ||
          c.customerCode.toLowerCase().contains(query) ||
          c.phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredCustomers;

    return SafeArea(
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Select Customer',
                      style: AppTypography.headlineSm(color: AppColors.navyContainer).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.customers.length}',
                        style: AppTypography.labelSm(color: AppColors.navyContainer).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.onAddNewCustomer != null)
                  TextButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add New'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.amberSecondary,
                      textStyle: AppTypography.labelMd(color: AppColors.amberSecondary).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: widget.onAddNewCustomer,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              autofocus: widget.selectedCustomer == null,
              onChanged: (_) => setState(() {}),
              style: AppTypography.bodyMd(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search name, phone, or customer code...',
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
          ),
          const SizedBox(height: 12),

          // Filter Pills: All, With Due, Overdue
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'With Due', 'Overdue'].map((tab) {
                  final isSelected = _filter == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => setState(() => _filter = tab),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.navyContainer : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tab,
                          style: AppTypography.labelSm(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ).copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.hairlineBorder),

          // List of Customers
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_search_rounded, size: 48, color: AppColors.outlineVariant),
                        const SizedBox(height: 10),
                        Text(
                          'No customers found for "${_searchController.text}"',
                          style: AppTypography.bodyMd(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.hairlineBorder),
                    itemBuilder: (context, index) {
                      final customer = filteredList[index];
                      final isSelected = widget.selectedCustomer?.id == customer.id;
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

                      return InkWell(
                        onTap: () => widget.onCustomerSelected(customer),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.surfaceContainerLow : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: avatarBg,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    initials,
                                    style: AppTypography.headlineSm(color: avatarText).copyWith(
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
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            customer.name,
                                            style: AppTypography.labelLg(color: AppColors.navyContainer).copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_circle_rounded, color: AppColors.emeraldSuccess, size: 18),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceContainerHigh,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            customer.customerCode,
                                            style: AppTypography.labelSm(color: AppColors.textSecondary).copyWith(
                                              fontSize: 9.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          customer.phone,
                                          style: AppTypography.bodySm(color: AppColors.textSecondary).copyWith(
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    CurrencyFormatter.format(customer.balance),
                                    style: AppTypography.currencyLedger(
                                      color: isOverdue
                                          ? AppColors.crimsonDanger
                                          : (hasDue ? AppColors.amberSecondary : AppColors.emeraldSuccess),
                                    ).copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isOverdue
                                        ? 'Overdue'
                                        : (hasDue ? 'Unsettled' : 'Cleared'),
                                    style: AppTypography.labelSm(
                                      color: isOverdue
                                          ? AppColors.crimsonDanger
                                          : (hasDue ? AppColors.textSecondary : AppColors.emeraldSuccess),
                                    ).copyWith(fontSize: 10),
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
        ],
      ),
    );
  }
}
