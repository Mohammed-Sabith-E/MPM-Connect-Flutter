import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/ledger_calculator.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/providers/app_providers.dart';
import '../../customers/models/customer_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class SettlementModal extends ConsumerStatefulWidget {
  final Customer customer;

  const SettlementModal({super.key, required this.customer});

  static Future<void> show(BuildContext context, {required Customer customer}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettlementModal(customer: customer),
    );
  }

  @override
  ConsumerState<SettlementModal> createState() => _SettlementModalState();
}

class _SettlementModalState extends ConsumerState<SettlementModal> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _paymentMethod = 'Cash';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _enteredAmount {
    return CurrencyFormatter.parse(_amountController.text);
  }

  double get _remainingBalance {
    return LedgerCalculator.calculateRemainingBalance(
      currentBalance: widget.customer.balance,
      paymentAmount: _enteredAmount,
    );
  }

  void _applyFullSettlement() {
    setState(() {
      _amountController.text = widget.customer.balance.toStringAsFixed(2);
    });
  }

  void _applyHalfSettlement() {
    setState(() {
      _amountController.text = (widget.customer.balance / 2).toStringAsFixed(2);
    });
  }

  Future<void> _handleConfirmPayment() async {
    final amount = _enteredAmount;
    final validationError = LedgerCalculator.validatePaymentAmount(paymentAmount: amount);
    if (validationError != null) {
      setState(() => _errorMessage = validationError);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProfileProvider).value;
      final paymentRepo = ref.read(paymentRepositoryProvider);

      await paymentRepo.recordSettlement(
        customerId: widget.customer.id,
        amount: amount,
        paymentMethod: _paymentMethod,
        paymentDate: DateTime.now(),
        notes: _notesController.text,
        receivedBy: user?.uid ?? 'SYSTEM',
        receivedByName: user?.name ?? 'Admin',
      );

      if (mounted) {
        Navigator.pop(context);
        AppToast.success('Payment of ${CurrencyFormatter.format(amount)} recorded successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modal Header Handle
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.hairlineBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Record Settlement', style: AppTypography.headlineMd(color: AppColors.navyDark)),
                        Text(widget.customer.name, style: AppTypography.bodySm(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current Balance Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navySoftTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairlineBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customer.balance < 0 ? 'CURRENT BALANCE (CREDIT)' : 'CURRENT OUTSTANDING',
                          style: AppTypography.labelSm(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(widget.customer.balance),
                          style: AppTypography.headlineLg(
                            color: widget.customer.balance > 0 ? AppColors.crimsonDanger : AppColors.emeraldSuccess,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _remainingBalance < 0 ? 'REMAINING (ADVANCE/CREDIT)' : 'REMAINING AFTER PAYMENT',
                          style: AppTypography.labelSm(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(_remainingBalance),
                          style: AppTypography.headlineLg(
                            color: _remainingBalance <= 0 ? AppColors.emeraldSuccess : AppColors.navyDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quick Fill Buttons (Full, 50%) - Only shown if customer has an outstanding balance
              if (widget.customer.balance > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.amberPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: _applyFullSettlement,
                        child: Text('Pay Full (${CurrencyFormatter.formatClean(widget.customer.balance)})', style: AppTypography.labelMd(color: AppColors.amberPrimary)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.hairlineBorder),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: _applyHalfSettlement,
                        child: Text('Pay 50%', style: AppTypography.labelMd(color: AppColors.navyPrimary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              if (_errorMessage != null) ...[
                Text(_errorMessage!, style: AppTypography.bodySm(color: AppColors.crimsonDanger)),
                const SizedBox(height: 8),
              ],

              // Amount Input
              AppTextField(
                controller: _amountController,
                label: 'Payment Amount',
                hint: '0.00',
                isMonetary: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Payment Method Chips
              Text('Payment Method', style: AppTypography.labelMd(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Cash', 'UPI', 'Bank', 'Other'].map((method) {
                  final isSelected = _paymentMethod == method;
                  return ChoiceChip(
                    label: Text(method),
                    selected: isSelected,
                    selectedColor: AppColors.navyPrimary,
                    labelStyle: AppTypography.labelSm(color: isSelected ? AppColors.textOnDark : AppColors.textPrimary),
                    onSelected: (selected) {
                      if (selected) setState(() => _paymentMethod = method);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _notesController,
                label: 'Notes / Reference (Optional)',
                hint: 'e.g. GPay Ref #12345',
              ),
              const SizedBox(height: 24),

              AppButton(
                text: 'Confirm Settlement',
                variant: AppButtonVariant.accent,
                isLoading: _isLoading,
                onPressed: _handleConfirmPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
