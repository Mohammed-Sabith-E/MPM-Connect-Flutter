import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/app_toast.dart';
import '../../../shared/widgets/app_button.dart';
import '../../auth/models/user_model.dart';
import '../../organizations/models/organization_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final user = userProfileAsync.asData?.value;
    final currentTheme = ref.watch(themeModeProvider);
    final currentOrg = ref.watch(currentOrgProvider) ?? Organization.mpm;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.headlineSm(color: AppColors.navyContainer)),
        iconTheme: const IconThemeData(color: AppColors.navyContainer),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Business Profile Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.navyPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/mpm_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: AppColors.navyPrimary,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('MPM CONNECT', style: AppTypography.headlineMd(color: AppColors.textOnDark)),
                      Text('Sovereign Ledger System', style: AppTypography.bodySm(color: AppColors.onPrimaryContainer)),
                      const SizedBox(height: 4),
                      Text('Currency: Indian Rupee (₹)', style: AppTypography.labelSm(color: AppColors.amberPrimary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Organization & Tenancy Card
          Text('ORGANIZATION', style: AppTypography.labelSm(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hairlineBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.navySoftTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_rounded,
                    color: AppColors.navyPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              currentOrg.name,
                              style: AppTypography.headlineSm(color: AppColors.navyDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.emeraldSuccess.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              currentOrg.status.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.emeraldSuccess,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ID: ${currentOrg.id}',
                        style: AppTypography.bodySm(color: AppColors.textMuted).copyWith(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // User Profile Card
          Text('MY PROFILE', style: AppTypography.labelSm(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          _EditableProfileCard(user: user),
          const SizedBox(height: 20),

          // Preferences & Appearance
          Text('APPEARANCE & SYSTEM', style: AppTypography.labelSm(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hairlineBorder),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Dark Theme Mode', style: AppTypography.bodyMd(color: AppColors.navyDark)),
                  subtitle: Text('Enable dark palette for low light conditions', style: AppTypography.bodySm(color: AppColors.textMuted)),
                  value: currentTheme == ThemeMode.dark,
                  activeColor: AppColors.navyPrimary,
                  onChanged: (isDark) {
                    ref.read(themeModeProvider.notifier).state = isDark ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: AppColors.navyPrimary),
                  title: Text('About MPM Connect', style: AppTypography.bodyMd(color: AppColors.navyDark)),
                  subtitle: Text('Version 1.0.0 (Production Release)', style: AppTypography.bodySm(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Developer Details Card
          Text('DEVELOPED BY', style: AppTypography.labelSm(color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairlineBorder),
                  ),
                  child: Image.asset(
                    'assets/images/zobotic_logo.png',
                    height: 46,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Text(
                      'ZOBOTIC INNOVATIONS',
                      style: AppTypography.headlineSm(color: AppColors.navyContainer).copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Zobotic Innovations',
                  style: AppTypography.headlineSm(color: AppColors.navyDark).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Official Technology & Engineering Partner',
                  style: AppTypography.bodySm(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: 'https://www.zobotic.in'));
                    AppToast.info('Website copied: www.zobotic.in');
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.language_rounded, color: AppColors.navyPrimary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Website', style: AppTypography.labelSm(color: AppColors.textMuted).copyWith(fontSize: 11)),
                              Text(
                                'www.zobotic.in',
                                style: AppTypography.bodyMd(color: AppColors.navyPrimary).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.copy_rounded, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: 'zoboticinnovations@gmail.com'));
                    AppToast.info('Email copied: zoboticinnovations@gmail.com');
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.email_outlined, color: AppColors.navyPrimary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Email', style: AppTypography.labelSm(color: AppColors.textMuted).copyWith(fontSize: 11)),
                              Text(
                                'zoboticinnovations@gmail.com',
                                style: AppTypography.bodyMd(color: AppColors.navyPrimary).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.copy_rounded, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Sign Out Button
          AppButton(
            text: 'Sign Out',
            icon: Icons.logout_rounded,
            variant: AppButtonVariant.outlined,
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─── Editable Profile Card ─────────────────────────────────────────────────
class _EditableProfileCard extends ConsumerStatefulWidget {
  final AppUser? user;
  const _EditableProfileCard({required this.user});

  @override
  ConsumerState<_EditableProfileCard> createState() => _EditableProfileCardState();
}

class _EditableProfileCardState extends ConsumerState<_EditableProfileCard> {
  late final TextEditingController _nameController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
  }

  @override
  void didUpdateWidget(_EditableProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.name != widget.user?.name && !_isEditing) {
      _nameController.text = widget.user?.name ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      AppToast.error('Name cannot be empty');
      return;
    }
    final uid = widget.user?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ref.invalidate(currentUserProfileProvider);
      if (mounted) {
        setState(() => _isEditing = false);
      }
      AppToast.success('Profile name updated');
    } catch (e) {
      AppToast.error('Something went wrong!');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final initial = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isEditing ? AppColors.navyPrimary.withValues(alpha: 0.35) : AppColors.hairlineBorder,
          width: _isEditing ? 1.5 : 1.0,
        ),
        boxShadow: _isEditing
            ? [
                BoxShadow(
                  color: AppColors.navyPrimary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [
                AppColors.shadowLevel1,
              ],
      ),
      child: _isEditing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.navySoftTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: AppTypography.headlineSm(color: AppColors.navyPrimary).copyWith(
                            fontWeight: FontWeight.bold,
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
                            'Edit Display Name',
                            style: AppTypography.headlineSm(color: AppColors.navyDark),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Update name shown on invoices & reports',
                            style: AppTypography.bodySm(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Styled Input Field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.canvasBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairlineBorder),
                  ),
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    style: AppTypography.bodyMd(color: AppColors.navyDark).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.navyPrimary,
                        size: 20,
                      ),
                      hintText: 'Enter your full name',
                      hintStyle: AppTypography.bodyMd(color: AppColors.textMuted),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () {
                                setState(() {
                                  _nameController.text = widget.user?.name ?? '';
                                  _isEditing = false;
                                });
                              },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.hairlineBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveName,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Changes',
                          style: AppTypography.labelLg(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navyPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.navySoftTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: AppTypography.headlineSm(color: AppColors.navyPrimary).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user?.name ?? 'Admin User',
                              style: AppTypography.headlineSm(color: AppColors.navyDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.navySoftTint,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              user?.role.label.toUpperCase() ?? 'ADMIN',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navyPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.mail_outline_rounded,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              user?.email ?? '',
                              style: AppTypography.bodySm(color: AppColors.textMuted),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() => _isEditing = true),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.canvasBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.hairlineBorder),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.navyPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
