import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/ledger_calculator.dart';
import '../../../core/providers/app_providers.dart';
import '../../customers/models/customer_model.dart';
import '../../../core/utils/invoice_number_generator.dart';
import '../../../core/utils/app_toast.dart';
import '../../../shared/widgets/mpm_app_header.dart';
import '../../../shared/widgets/searchable_customer_picker.dart';

class NewTransactionScreen extends ConsumerStatefulWidget {
  final String? preselectedCustomerId;

  const NewTransactionScreen({super.key, this.preselectedCustomerId});

  @override
  ConsumerState<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends ConsumerState<NewTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceAmountController = TextEditingController();
  final _paymentReceivedController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _selectedCustomer;
  String _paymentMethod = 'Cash';
  DateTime _invoiceDate = DateTime.now();
  String _previewInvoiceNumber = 'INV-000001';

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _invoiceAmountController.addListener(() => setState(() {}));
    _paymentReceivedController.addListener(() => setState(() {}));
    _loadNextInvoiceNumber();

    if (widget.preselectedCustomerId != null) {
      _loadPreselectedCustomer();
    }
  }

  Future<void> _loadNextInvoiceNumber() async {
    try {
      final firestore = ref.read(firestoreProvider);
      final inv = await InvoiceNumberGenerator.previewNextInvoiceNumber(firestore);
      if (mounted) setState(() => _previewInvoiceNumber = inv);
    } catch (_) {}
  }

  Future<void> _loadPreselectedCustomer() async {
    final customer = await ref.read(customerRepositoryProvider).getCustomerById(widget.preselectedCustomerId!);
    if (customer != null && mounted) {
      setState(() {
        _selectedCustomer = customer;
      });
    }
  }

  @override
  void dispose() {
    _invoiceAmountController.dispose();
    _paymentReceivedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _previousBalance => _selectedCustomer?.balance ?? 0.0;
  double get _invoiceAmount => CurrencyFormatter.parse(_invoiceAmountController.text);
  double get _paymentReceived => CurrencyFormatter.parse(_paymentReceivedController.text);

  double get _newBalance {
    return LedgerCalculator.calculateNewBalance(
      previousBalance: _previousBalance,
      invoiceAmount: _invoiceAmount,
      paymentReceived: _paymentReceived,
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.navyContainer),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _invoiceDate = picked);
    }
  }

  Future<void> _handleSaveTransaction() async {
    if (_selectedCustomer == null) {
      setState(() => _errorMessage = 'Please select a customer');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_invoiceAmount <= 0) {
      setState(() => _errorMessage = 'Invoice amount must be greater than ₹0');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProfileProvider).value;
      final txRepo = ref.read(transactionRepositoryProvider);

      final transaction = await txRepo.createInvoiceTransaction(
        customerId: _selectedCustomer!.id,
        invoiceAmount: _invoiceAmount,
        paymentReceived: _paymentReceived,
        paymentMethod: _paymentMethod,
        invoiceDate: _invoiceDate,
        notes: _notesController.text,
        salesmanId: null,
        salesmanName: null,
        createdBy: user?.uid ?? 'SYSTEM',
        createdByName: user?.name ?? 'Admin',
      );

      if (mounted) {
        context.pop();
        context.push('/transactions/${transaction.id}');
        AppToast.success('Invoice ${transaction.invoiceNumber} recorded successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception:', '').trim());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider(null));

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: MpmAppHeader(
        title: 'New Transaction',
        showBackButton: true,
        organization: ref.watch(currentOrgProvider),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          border: const Border(top: BorderSide(color: AppColors.hairlineBorder)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(15, 43, 72, 0.05),
              offset: Offset(0, -3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (MediaQuery.of(context).viewInsets.bottom > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  border: Border(bottom: BorderSide(color: AppColors.hairlineBorder)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Entering Amount',
                      style: AppTypography.labelSm(color: AppColors.textSecondary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    InkWell(
                      onTap: () => FocusScope.of(context).unfocus(),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.navyContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.keyboard_hide_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Close Keyboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.navyContainer,
                          side: const BorderSide(color: AppColors.hairlineBorder),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => context.pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_rounded, size: 20),
                        label: Text(_isLoading ? 'Saving...' : 'Generate & Save Invoice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amberContainer,
                          foregroundColor: AppColors.onSecondaryContainer,
                          elevation: 0,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: AppTypography.labelLg(color: AppColors.onSecondaryContainer).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _isLoading ? null : _handleSaveTransaction,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Step Indicator Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: AppColors.navyContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '2',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'STEP 2 OF 3 • INVOICE GENERATION',
                        style: AppTypography.labelSm(color: AppColors.textSecondary).copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryFixed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.amberPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Draft Mode',
                          style: AppTypography.labelSm(color: AppColors.onSecondaryFixed).copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.crimsonLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.crimsonDanger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.crimsonDanger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!, style: AppTypography.bodySm(color: AppColors.crimsonDanger)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 2. Customer Selector Card
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
                child: _selectedCustomer != null
                    ? Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _selectedCustomer!.name.isNotEmpty
                                            ? _selectedCustomer!.name.split(' ').map((s) => s.isNotEmpty ? s[0] : '').take(2).join().toUpperCase()
                                            : 'CU',
                                        style: AppTypography.headlineSm(color: AppColors.navyContainer).copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _selectedCustomer!.name,
                                            style: AppTypography.headlineSm(color: AppColors.navyContainer).copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified_rounded, size: 16, color: AppColors.onTertiaryContainer),
                                        ],
                                      ),
                                      Text(
                                        _selectedCustomer!.phoneNumber,
                                        style: AppTypography.bodySm(color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                label: const Text('Change'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.amberSecondary,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                onPressed: () async {
                                  final customers = await ref.read(customerRepositoryProvider).streamCustomers().first;
                                  if (context.mounted) {
                                    final picked = await SearchableCustomerPicker.show(
                                      context,
                                      customers: customers,
                                      selectedCustomer: _selectedCustomer,
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        _selectedCustomer = picked;
                                      });
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryFixed.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: const BoxDecoration(
                                        color: AppColors.amberContainer,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'PREVIOUS BALANCE',
                                          style: AppTypography.labelSm(color: AppColors.onSecondaryFixedVariant).copyWith(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Unsettled credit ledger',
                                          style: AppTypography.bodySm(color: AppColors.textSecondary).copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Text(
                                  CurrencyFormatter.format(_selectedCustomer!.balance),
                                  style: AppTypography.currencyLedger(color: AppColors.amberSecondary).copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : customersAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error loading customers: $e'),
                        data: (customers) {
                          return InkWell(
                            onTap: () async {
                              final picked = await SearchableCustomerPicker.show(
                                context,
                                customers: customers,
                                selectedCustomer: _selectedCustomer,
                                onAddNewCustomer: () => context.push('/customers/add'),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedCustomer = picked;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.hairlineBorder),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_search_rounded, color: AppColors.navyContainer, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Select Customer *',
                                          style: AppTypography.labelLg(color: AppColors.navyContainer).copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Tap to search by name, phone, or code (${customers.length} available)',
                                          style: AppTypography.bodySm(color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // 3. Invoice Details Card
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded, color: AppColors.amberSecondary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Invoice Details',
                              style: AppTypography.headlineSm(color: AppColors.navyContainer).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.navyContainer.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.hairlineBorder),
                          ),
                          child: Text(
                            '#$_previewInvoiceNumber',
                            style: AppTypography.labelSm(color: AppColors.navyContainer).copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Billing Date Row (No salesman linking)
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.hairlineBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.navyContainer),
                                const SizedBox(width: 10),
                                Text(
                                  'Invoice Date: ${DateFormatter.formatDate(_invoiceDate)}',
                                  style: AppTypography.bodyMd(color: AppColors.textPrimary).copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary, size: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. Invoice Total Amount Input
                    Text(
                      'Invoice Total Amount *',
                      style: AppTypography.labelLg(color: AppColors.navyContainer).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _invoiceAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      style: AppTypography.currencyDisplay(color: AppColors.navyContainer).copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        hintText: '0.00',
                        hintStyle: AppTypography.currencyDisplay(color: AppColors.textMuted).copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.normal,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 8),
                          child: Text(
                            '₹',
                            style: AppTypography.displayLg(color: AppColors.navyContainer).copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
                        suffixIcon: _invoiceAmountController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _invoiceAmountController.clear();
                                  setState(() {});
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.hairlineBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.hairlineBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.navyPrimary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.crimsonDanger),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Enter amount';
                        if (CurrencyFormatter.parse(val) <= 0) return 'Must be > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Initial Payment Received Input (Paid Today)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment Received Today',
                          style: AppTypography.labelLg(color: AppColors.navyContainer).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Optional / Cash or UPI',
                          style: AppTypography.bodySm(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _paymentReceivedController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                      style: AppTypography.currencyLedger(color: AppColors.emeraldSuccess).copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        hintText: '0.00 (Optional)',
                        hintStyle: AppTypography.currencyLedger(color: AppColors.textMuted).copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 14, right: 8),
                          child: Text(
                            '₹',
                            style: AppTypography.headlineSm(color: AppColors.emeraldSuccess).copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
                        suffixIcon: _paymentReceivedController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _paymentReceivedController.clear();
                                  setState(() {});
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.hairlineBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.hairlineBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.navyPrimary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Payment Method selector
                    if (_paymentReceived > 0) ...[
                      Row(
                        children: ['Cash', 'UPI', 'Cheque', 'Bank Transfer'].map((method) {
                          final isSelected = _paymentMethod == method;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(method),
                              selected: isSelected,
                              selectedColor: AppColors.navyContainer,
                              labelStyle: AppTypography.labelSm(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                              onSelected: (selected) {
                                if (selected) setState(() => _paymentMethod = method);
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Notes / Reference field
                    TextFormField(
                      controller: _notesController,
                      style: AppTypography.bodyMd(color: AppColors.textPrimary),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        labelText: 'Notes / PO Reference',
                        prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.hairlineBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.hairlineBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.navyPrimary, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Live Balance Calculation Ledger Card
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
                    Text(
                      'BALANCE CALCULATION BREAKDOWN',
                      style: AppTypography.labelSm(color: AppColors.navyContainer).copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCalcRow('Previous Unsettled Balance', CurrencyFormatter.format(_previousBalance), AppColors.textPrimary),
                    const SizedBox(height: 6),
                    _buildCalcRow('+ Current Invoice Amount', CurrencyFormatter.format(_invoiceAmount), AppColors.navyContainer),
                    const SizedBox(height: 6),
                    _buildCalcRow('- Payment Received Today', CurrencyFormatter.format(_paymentReceived), AppColors.emeraldSuccess),
                    const SizedBox(height: 8),
                    const Divider(color: AppColors.hairlineBorder),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New Customer Balance',
                          style: AppTypography.headlineSm(color: AppColors.navyContainer).copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(_newBalance),
                          style: AppTypography.currencyDisplay(
                            color: _newBalance > 0 ? AppColors.crimsonDanger : AppColors.emeraldSuccess,
                          ).copyWith(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildCalcRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodySm(color: AppColors.textSecondary)),
        Text(
          value,
          style: AppTypography.currencyLedger(color: color).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
