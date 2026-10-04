import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class AddSalesmanScreen extends ConsumerStatefulWidget {
  const AddSalesmanScreen({super.key});

  @override
  ConsumerState<AddSalesmanScreen> createState() => _AddSalesmanScreenState();
}

class _AddSalesmanScreenState extends ConsumerState<AddSalesmanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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
      final salesmanRepo = ref.read(salesmanRepositoryProvider);

      await salesmanRepo.createSalesman(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        adminUid: user?.uid ?? 'ADMIN',
        adminName: user?.name ?? 'Admin',
      );

      if (mounted) {
        context.pop();
        AppToast.success('Salesman ${_nameController.text.trim()} account created! They can now log in.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception:', '').replaceAll(RegExp(r'\[.*?\]'), '').trim());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.canvasBackground,
        appBar: AppBar(
          backgroundColor: AppColors.canvasBackground,
          elevation: 0,
          title: Text(
            'Add New Salesman',
            style: AppTypography.headlineSm(color: AppColors.navyContainer),
          ),
          iconTheme: const IconThemeData(color: AppColors.navyContainer),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.navyContainer.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairlineBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.amberSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The salesman will use this email and password to log in to MPM Connect.',
                          style: AppTypography.bodySm(color: AppColors.navyContainer).copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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

                // 1. Name *
                AppTextField(
                  controller: _nameController,
                  label: 'Full Name *',
                  hint: 'e.g. Anand Kumar',
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.navyContainer),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Full Name is required' : null,
                ),
                const SizedBox(height: 20),

                // 2. Email *
                AppTextField(
                  controller: _emailController,
                  label: 'Email Address *',
                  hint: 'e.g. anand@mpmconnect.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.navyContainer),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return 'Email is required for login';
                    if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email address';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 3. Password *
                AppTextField(
                  controller: _passwordController,
                  label: 'Login Password *',
                  hint: 'At least 6 characters',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSave(),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.navyContainer),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Password is required for login';
                    if (val.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                AppButton(
                  text: 'Create Salesman Account',
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
