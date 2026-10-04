import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/app_toast.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../organizations/models/organization_model.dart';
import '../../auth/models/user_model.dart';

class SuperAdminScreen extends ConsumerStatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  ConsumerState<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends ConsumerState<SuperAdminScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _generatePassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = math.Random();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  void _showCreateOrganizationDialog() {
    final formKey = GlobalKey<FormState>();
    final orgNameController = TextEditingController();
    final adminEmailController = TextEditingController();
    final adminPasswordController = TextEditingController(text: _generatePassword());

    bool isSubmitting = false;
    bool obscurePassword = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.navySoftTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_business_rounded,
                              color: AppColors.navyPrimary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Organization',
                                  style: AppTypography.headlineSm(color: AppColors.navyDark).copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Set up organization name and credentials',
                                  style: AppTypography.bodySm(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Section: Organization
                      Text(
                        'ORGANIZATION INFO',
                        style: AppTypography.labelSm(color: AppColors.textMuted).copyWith(
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: orgNameController,
                        label: 'Organization Name *',
                        hint: 'e.g. MPM Traders, Zobotic Stores',
                        prefixIcon: const Icon(Icons.storefront_rounded, color: AppColors.navyPrimary, size: 20),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Organization name is required' : null,
                      ),
                      const SizedBox(height: 18),

                      // Section: Credentials
                      Text(
                        'ORGANIZATION LOGIN CREDENTIALS',
                        style: AppTypography.labelSm(color: AppColors.textMuted).copyWith(
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppTextField(
                        controller: adminEmailController,
                        label: 'Email *',
                        hint: 'org@mpmconnect.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.navyPrimary, size: 20),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: adminPasswordController,
                        label: 'Password *',
                        hint: 'Min 6 characters',
                        obscureText: obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.navyPrimary, size: 20),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Generate Random Password',
                              icon: const Icon(Icons.refresh_rounded, color: AppColors.amberPrimary, size: 20),
                              onPressed: () {
                                setSheetState(() {
                                  adminPasswordController.text = _generatePassword();
                                });
                              },
                            ),
                            IconButton(
                              tooltip: obscurePassword ? 'Show password' : 'Hide password',
                              icon: Icon(
                                obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setSheetState(() => obscurePassword = !obscurePassword),
                            ),
                          ],
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Password is required';
                          if (v.trim().length < 6) return 'Password must be at least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setSheetState(() => isSubmitting = true);

                                  try {
                                    final orgName = orgNameController.text.trim();
                                    final email = adminEmailController.text.trim();
                                    final password = adminPasswordController.text.trim();

                                    final authRepo = ref.read(authRepositoryProvider);
                                    final result = await authRepo.createOrganizationWithAdmin(
                                      organizationName: orgName,
                                      adminEmail: email,
                                      adminPassword: password,
                                      adminName: orgName,
                                      adminPhone: '',
                                    );

                                    ref.invalidate(allOrganizationsStreamProvider);
                                    ref.invalidate(allUsersStreamProvider);

                                    if (context.mounted) {
                                      Navigator.pop(sheetCtx);
                                      _showCreatedCredentialsDialog(
                                        orgName: orgName,
                                        orgId: result['organizationId'] as String,
                                        email: email,
                                        password: password,
                                      );
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSubmitting = false);
                                    AppToast.error(e.toString().replaceAll('Exception:', '').trim());
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.navyPrimary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                )
                              : const Icon(Icons.check_rounded, size: 20),
                          label: Text(
                            isSubmitting ? 'Creating Organization...' : 'Add Organization',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreatedCredentialsDialog({
    required String orgName,
    required String orgId,
    required String email,
    required String password,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.emeraldSuccess, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Organization Created!',
                style: AppTypography.headlineSm(color: AppColors.navyDark),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tenant: $orgName', style: AppTypography.bodyMd(color: AppColors.navyDark).copyWith(fontWeight: FontWeight.bold)),
            Text('ID: $orgId', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.navyPrimary)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.canvasBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.hairlineBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Admin Login Credentials:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Text('Email: $email', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text('Password: $password', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.amberPrimary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Credentials'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: 'Organization: $orgName\nEmail: $email\nPassword: $password'));
              AppToast.success('Credentials copied to clipboard');
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(allOrganizationsStreamProvider);
    final usersAsync = ref.watch(allUsersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.navySoftTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.navyPrimary, size: 22),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Super Admin',
                  style: AppTypography.headlineSm(color: AppColors.navyDark).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'MPM Connect Multi-Tenant',
                  style: AppTypography.bodySm(color: AppColors.textMuted).copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppColors.crimsonDanger),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Log out from Super Admin?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimsonDanger),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Log Out', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateOrganizationDialog,
        backgroundColor: AppColors.navyPrimary,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text(
          'Add Organization',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: orgsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading organizations: $e')),
        data: (orgs) {
          final allUsers = usersAsync.asData?.value ?? [];

          final totalOrgs = orgs.length;
          final totalAdmins = allUsers.where((u) => u.role == UserRole.admin).length;
          final totalSalesmen = allUsers.where((u) => u.role == UserRole.salesman).length;

          final filteredOrgs = orgs.where((org) {
            final q = _searchQuery.toLowerCase();
            return org.name.toLowerCase().contains(q) || org.id.toLowerCase().contains(q);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allOrganizationsStreamProvider);
              ref.invalidate(allUsersStreamProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Unified Metrics Card (Optimized for Mobile)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.hairlineBorder),
                    boxShadow: const [AppColors.shadowLevel1],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetricColumn(
                          title: 'Tenants',
                          value: '$totalOrgs',
                          icon: Icons.apartment_rounded,
                          iconColor: AppColors.navyPrimary,
                        ),
                      ),
                      Container(height: 36, width: 1, color: AppColors.hairlineBorder),
                      Expanded(
                        child: _MetricColumn(
                          title: 'Admins',
                          value: '$totalAdmins',
                          icon: Icons.manage_accounts_rounded,
                          iconColor: AppColors.emeraldSuccess,
                        ),
                      ),
                      Container(height: 36, width: 1, color: AppColors.hairlineBorder),
                      Expanded(
                        child: _MetricColumn(
                          title: 'Salesmen',
                          value: '$totalSalesmen',
                          icon: Icons.badge_rounded,
                          iconColor: AppColors.amberPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search tenants by name or ID...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.hairlineBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.hairlineBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'REGISTERED TENANTS (${filteredOrgs.length})',
                      style: AppTypography.labelSm(color: AppColors.textMuted).copyWith(
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Format: org_<12hex>',
                      style: AppTypography.bodySm(color: AppColors.textMuted).copyWith(fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Empty State or List
                if (filteredOrgs.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.hairlineBorder),
                      boxShadow: const [AppColors.shadowLevel1],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.navySoftTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.domain_disabled_rounded,
                            size: 40,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No organizations match your search'
                              : 'No organizations created yet',
                          style: AppTypography.headlineSm(color: AppColors.navyDark).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try searching with another organization name or ID.'
                              : 'Tap "+ Add Organization" below to create your first tenant.',
                          style: AppTypography.bodySm(color: AppColors.textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredOrgs.map((org) {
                    final orgUsers = allUsers.where((u) => u.organizationId == org.id).toList();
                    final adminUser = orgUsers.firstWhere(
                      (u) => u.role == UserRole.admin,
                      orElse: () => AppUser(
                        uid: '',
                        name: 'Admin',
                        email: '—',
                        phone: '',
                        role: UserRole.admin,
                        createdAt: DateTime.now(),
                      ),
                    );
                    final salesmen = orgUsers.where((u) => u.role == UserRole.salesman).toList();

                    return _OrganizationTenantCard(
                      org: org,
                      adminUser: adminUser,
                      salesmen: salesmen,
                    );
                  }),
                const SizedBox(height: 80), // Extra space for FAB
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _MetricColumn({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.headlineSm(color: AppColors.navyDark).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: AppTypography.bodySm(color: AppColors.textMuted).copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _OrganizationTenantCard extends StatefulWidget {
  final Organization org;
  final AppUser adminUser;
  final List<AppUser> salesmen;

  const _OrganizationTenantCard({
    required this.org,
    required this.adminUser,
    required this.salesmen,
  });

  @override
  State<_OrganizationTenantCard> createState() => _OrganizationTenantCardState();
}

class _OrganizationTenantCardState extends State<_OrganizationTenantCard> {
  bool _isExpanded = false;
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final org = widget.org;
    final admin = widget.adminUser;
    final salesmen = widget.salesmen;
    final createdDateStr = DateFormat('d MMM yyyy').format(org.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairlineBorder),
        boxShadow: const [AppColors.shadowLevel1],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.navySoftTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          org.name.isNotEmpty ? org.name[0].toUpperCase() : 'O',
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  org.name,
                                  style: AppTypography.headlineSm(color: AppColors.navyDark).copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldSuccess.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  org.status.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.emeraldSuccess,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: org.id));
                                  AppToast.success('Copied Org ID: ${org.id}');
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      org.id,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: AppColors.navyPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.copy_rounded, size: 12, color: AppColors.textMuted),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('• $createdDateStr', style: AppTypography.bodySm(color: AppColors.textMuted).copyWith(fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.hairlineBorder),
                const SizedBox(height: 12),

                // Organization Admin Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.canvasBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairlineBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.admin_panel_settings_rounded, size: 18, color: AppColors.navyPrimary),
                              const SizedBox(width: 6),
                              Text(
                                'Organization Admin',
                                style: AppTypography.labelMd(color: AppColors.navyDark).copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: 'Copy Login Info',
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.navyPrimary),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                text: 'Organization: ${org.name}\nEmail: ${admin.email}\nPassword: ${admin.password ?? ""}',
                              ));
                              AppToast.success('Copied credentials for ${org.name}');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 15, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              admin.email,
                              style: AppTypography.bodyMd(color: AppColors.navyDark).copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (admin.password != null && admin.password!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.amberPrimary),
                            const SizedBox(width: 6),
                            Text(
                              _showPassword ? admin.password! : '••••••••',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                color: AppColors.amberPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => setState(() => _showPassword = !_showPassword),
                              child: Icon(
                                _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Salesmen Accordion Toggle
                InkWell(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.badge_rounded, size: 16, color: AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              'Salesmen (${salesmen.length})',
                              style: AppTypography.labelMd(color: AppColors.navyDark).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isExpanded) ...[
                  const SizedBox(height: 8),
                  if (salesmen.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: AppColors.canvasBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'No salesmen registered yet by this organization admin.',
                        style: AppTypography.bodySm(color: AppColors.textMuted).copyWith(fontSize: 12),
                      ),
                    )
                  else
                    ...salesmen.map((salesman) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.canvasBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.hairlineBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textMuted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(salesman.name, style: AppTypography.labelMd(color: AppColors.navyDark).copyWith(fontWeight: FontWeight.w600)),
                                  Text(
                                    '${salesman.email} ${salesman.phone.isNotEmpty ? "• ${salesman.phone}" : ""}',
                                    style: AppTypography.bodySm(color: AppColors.textMuted).copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (salesman.password != null && salesman.password!.isNotEmpty)
                              IconButton(
                                tooltip: 'Copy Credentials',
                                icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.navyPrimary),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                    text: 'Salesman: ${salesman.name}\nEmail: ${salesman.email}\nPassword: ${salesman.password}',
                                  ));
                                  AppToast.success('Copied credentials for ${salesman.name}');
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
