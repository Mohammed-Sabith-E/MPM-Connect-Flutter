import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _mapAuthError(Object error) {
    final errStr = error.toString().replaceAll('Exception:', '').trim();
    final lower = errStr.toLowerCase();

    if (lower.contains('invalid email or password') ||
        lower.contains('invalid-credential') ||
        lower.contains('wrong-password') ||
        lower.contains('user-not-found')) {
      return 'Invalid email or password';
    }
    if (lower.contains('not assigned to an organization')) {
      return 'Your account is not assigned to an organization.';
    }
    if (lower.contains('disabled')) {
      return 'This account has been disabled. Please contact the administrator.';
    }
    if (lower.contains('already registered')) {
      return 'This email is already registered.';
    }

    return 'Something went wrong!';
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final loggedUser = await authRepo.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (loggedUser.isSuperAdmin) {
          context.go('/super-admin');
        } else {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _mapAuthError(e);
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
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // MPM Logo & Brand Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.hairlineBorder),
                          boxShadow: const [
                            AppColors.shadowLevel2,
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/MPM PNG.png',
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/mpm_logo.png',
                            height: 64,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'MPM CONNECT',
                      style: AppTypography.displayLg(color: AppColors.navyDark),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customer Credit & Collection Management',
                      style: AppTypography.bodyMd(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // Card Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.hairlineBorder),
                        boxShadow: const [
                          AppColors.shadowLevel1,
                          AppColors.shadowLevel1Ambient,
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sign In',
                            style: AppTypography.headlineMd(color: AppColors.navyDark),
                          ),
                          const SizedBox(height: 20),

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.crimsonLight,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.crimsonDanger.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.crimsonDanger, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTypography.bodySm(color: AppColors.crimsonDanger),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          AppTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'admin@mpmconnect.com',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Email is required';
                              if (!val.contains('@')) return 'Enter a valid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: '••••••••',
                            obscureText: _obscurePassword,
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Password is required';
                              if (val.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          AppButton(
                            text: 'Sign In',
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Sovereign Ledger • Version 1.0.0',
                      style: AppTypography.labelSm(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
