import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class AddEditCustomerScreen extends ConsumerStatefulWidget {
  final String? customerId;
  final String? initialName;
  final String? initialPhone;

  const AddEditCustomerScreen({
    super.key,
    this.customerId,
    this.initialName,
    this.initialPhone,
  });

  @override
  ConsumerState<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends ConsumerState<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _customerCode = '';
  bool _isLoading = false;
  bool _isFetchingInitial = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameController.text = widget.initialName!;
    }
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      _phoneController.text = widget.initialPhone!;
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isFetchingInitial = true);
    final customerRepo = ref.read(customerRepositoryProvider);

    if (widget.customerId != null) {
      final customer = await customerRepo.getCustomerById(widget.customerId!);
      if (customer != null && mounted) {
        _customerCode = customer.customerCode;
        _nameController.text = customer.name;
        _phoneController.text = customer.phone;
      }
    } else {
      // Pre-fill from contacts if provided
      if (widget.initialName != null && widget.initialName!.isNotEmpty) {
        _nameController.text = widget.initialName!;
      }
      if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
        _phoneController.text = widget.initialPhone!;
      }
      // Auto-generate next unique series customer ID
      _customerCode = await customerRepo.getNextCustomerCode();
    }

    if (mounted) setState(() => _isFetchingInitial = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProfileProvider).value;
      final customerRepo = ref.read(customerRepositoryProvider);

      if (widget.customerId == null) {
        // Create new customer with 3 fields
        await customerRepo.createCustomer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          customCustomerCode: _customerCode,
          createdBy: user?.uid ?? 'SYSTEM',
          createdByName: user?.name ?? 'Admin',
        );
      } else {
        // Update customer
        await customerRepo.updateCustomer(
          customerId: widget.customerId!,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          updatedBy: user?.uid ?? 'SYSTEM',
          updatedByName: user?.name ?? 'Admin',
        );
      }

      if (mounted) {
        context.pop();
        AppToast.success(
          widget.customerId == null
              ? 'Customer $_customerCode created successfully!'
              : 'Customer updated successfully!',
        );
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
    final isEdit = widget.customerId != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.canvasBackground,
        appBar: AppBar(
          backgroundColor: AppColors.canvasBackground,
          elevation: 0,
          title: Text(
            isEdit ? 'Edit Customer' : 'Add New Customer',
            style: AppTypography.headlineSm(color: AppColors.navyContainer),
          ),
          iconTheme: const IconThemeData(color: AppColors.navyContainer),
        ),
        body: _isFetchingInitial
            ? const Center(child: CircularProgressIndicator(color: AppColors.amberSecondary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.crimsonLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.crimsonDanger.withValues(alpha: 0.3)),
                          ),
                          child: Text(_errorMessage!, style: AppTypography.bodySm(color: AppColors.crimsonDanger)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // 1. Customer ID (Auto-generated & Non-editable, unique in series)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Customer ID',
                                style: AppTypography.labelMd(color: AppColors.textPrimary).copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.navyContainer.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Auto-generated',
                                  style: AppTypography.labelSm(color: AppColors.navyContainer).copyWith(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.hairlineBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.tag_rounded, color: AppColors.amberSecondary, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _customerCode.isEmpty ? 'Generating...' : _customerCode,
                                    style: AppTypography.bodyMd(color: AppColors.navyContainer).copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 2. Customer Name * (Required)
                      AppTextField(
                        controller: _nameController,
                        label: 'Customer Name *',
                        hint: 'e.g. Royal Gold Traders',
                        textInputAction: TextInputAction.next,
                        prefixIcon: const Icon(Icons.business_outlined, color: AppColors.navyContainer),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Customer name is required' : null,
                      ),
                      const SizedBox(height: 20),

                      // 3. Mobile Number (Optional, not mandatory)
                      AppTextField(
                        controller: _phoneController,
                        label: 'Mobile Number (Optional)',
                        hint: 'e.g. 9876543210',
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => FocusScope.of(context).unfocus(),
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      AppButton(
                        text: isEdit ? 'Update Customer' : 'Create Customer',
                        isLoading: _isLoading,
                        onPressed: _handleSave,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
