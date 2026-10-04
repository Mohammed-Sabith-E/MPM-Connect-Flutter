import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/organizations/models/organization_model.dart';

class MpmAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final VoidCallback? onNotificationTap;
  final int? notificationCount;
  final VoidCallback? onProfileTap;
  final List<Widget>? actions;
  final Organization? organization;

  const MpmAppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.onNotificationTap,
    this.notificationCount,
    this.onProfileTap,
    this.actions,
    this.organization,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasBackground.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: AppColors.hairlineBorder, width: 0.8),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (showBackButton) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navyPrimary),
                  tooltip: 'Back',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                ),
                const SizedBox(width: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/MPM PNG.png',
                    height: 26,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.navyContainer,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: AppTypography.headlineSm(color: AppColors.navyContainer).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/MPM PNG.png',
                    height: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.navyContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'MPM Connect',
                            style: AppTypography.headlineSm(color: AppColors.navyContainer).copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!.toUpperCase(),
                          style: AppTypography.labelSm(color: AppColors.textSecondary).copyWith(
                            fontSize: 10,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (actions != null) ...actions!,
              // Notifications bell with badge (only shown if onNotificationTap provided)
              if (onNotificationTap != null) ...[
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
                      tooltip: 'Notifications',
                      onPressed: onNotificationTap,
                    ),
                    if (notificationCount != null && notificationCount! > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.crimsonDanger,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              notificationCount! > 9 ? '9+' : '$notificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
              // User Avatar with online indicator
              GestureDetector(
                onTap: onProfileTap ?? () => context.push('/settings'),
                child: Stack(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surfaceContainer, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/manager_avatar.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.navyContainer,
                            child: const Center(
                              child: Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryFixedDim,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.canvasBackground, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
