import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/permission_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/models/user_model.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/state_views.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  void _showCreateUserDialog(String orgId) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    UserRole selectedRole = UserRole.salesman;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('Create New User', style: AppTypography.headlineSm(color: AppColors.navyDark)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      controller: nameController,
                      label: 'Full Name *',
                      hint: 'e.g. John',
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: emailController,
                      label: 'Email *',
                      hint: 'john@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: phoneController,
                      label: 'Phone',
                      hint: '+91 98765 43210',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: passwordController,
                      label: 'Password *',
                      hint: '••••••••',
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Assigned Role'),
                      items: UserRole.values
                          .where((role) => role != UserRole.superAdmin)
                          .map((role) {
                        return DropdownMenuItem(value: role, child: Text(role.label));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedRole = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navyPrimary,
                    foregroundColor: AppColors.textOnDark,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty ||
                              emailController.text.trim().isEmpty ||
                              passwordController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill name, email and password')),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(dialogCtx);

                          try {
                            final currentAdmin = ref.read(currentUserProfileProvider).value;
                            await ref.read(authRepositoryProvider).adminCreateUser(
                              adminUid: currentAdmin?.uid ?? 'ADMIN',
                              adminName: currentAdmin?.name ?? 'Admin',
                              adminOrgId: orgId,
                              name: nameController.text.trim(),
                              email: emailController.text.trim(),
                              password: passwordController.text,
                              phone: phoneController.text.trim(),
                              role: selectedRole,
                            );
                            navigator.pop();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('User ${nameController.text} created successfully!'),
                                backgroundColor: AppColors.emeraldSuccess,
                              ),
                            );
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.crimsonDanger),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create User'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firestoreProvider);
    final currentOrg = ref.watch(currentOrgProvider);

    if (currentOrg == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('User Management', style: AppTypography.headlineSm(color: AppColors.navyContainer)),
        ),
        body: const Center(
          child: Text('Your account is not assigned to an organization.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('User Management', style: AppTypography.headlineSm(color: AppColors.navyContainer)),
        iconTheme: const IconThemeData(color: AppColors.navyContainer),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: AppColors.textOnDark,
        onPressed: () => _showCreateUserDialog(currentOrg.id),
        child: const Icon(Icons.person_add_alt_1_rounded),
      ),
      body: StreamBuilder(
        // Stream users belonging strictly to current organization
        stream: firestore
            .collection('users')
            .where('organizationId', isEqualTo: currentOrg.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingStateView(message: 'Loading users...');
          }
          if (snapshot.hasError) {
            return ErrorStateView(message: snapshot.error.toString());
          }

          final docs = snapshot.data?.docs ?? [];
          final users = docs.map((doc) => AppUser.fromMap(doc.data(), doc.id)).toList();

          if (users.isEmpty) {
            return const Center(child: Text('No users in this organization.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = users[index];

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairlineBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: user.isActive ? AppColors.navySoftTint : AppColors.crimsonLight,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: AppTypography.headlineSm(
                          color: user.isActive ? AppColors.navyPrimary : AppColors.crimsonDanger,
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
                                  user.name,
                                  style: AppTypography.headlineSm(color: AppColors.navyDark),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(user.role.label, style: AppTypography.labelSm(color: AppColors.navyPrimary)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${user.email}${user.phone.isNotEmpty ? " • ${user.phone}" : ""}',
                              style: AppTypography.bodySm(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Switch(
                      value: user.isActive,
                      activeColor: AppColors.navyPrimary,
                      onChanged: (val) async {
                        final currentAdmin = ref.read(currentUserProfileProvider).value;
                        await ref.read(authRepositoryProvider).setUserActiveStatus(
                          adminUid: currentAdmin?.uid ?? 'ADMIN',
                          adminName: currentAdmin?.name ?? 'Admin',
                          organizationId: currentOrg.id,
                          targetUserId: user.uid,
                          targetUserName: user.name,
                          isActive: val,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
