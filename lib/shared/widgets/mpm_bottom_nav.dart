import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum MpmNavTab {
  dashboard,
  customers,
  transactions,
  more,
}

class MpmBottomNav extends StatelessWidget {
  final MpmNavTab currentTab;

  const MpmBottomNav({
    super.key,
    required this.currentTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasBackground.withValues(alpha: 0.95),
        border: const Border(
          top: BorderSide(color: AppColors.hairlineBorder, width: 0.8),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(15, 43, 72, 0.05),
            offset: Offset(0, -2),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _buildNavItem(
                context: context,
                tab: MpmNavTab.dashboard,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
                route: '/dashboard',
              ),
              _buildNavItem(
                context: context,
                tab: MpmNavTab.customers,
                icon: Icons.group_outlined,
                activeIcon: Icons.group_rounded,
                label: 'Customers',
                route: '/customers',
              ),
              _buildNavItem(
                context: context,
                tab: MpmNavTab.transactions,
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long_rounded,
                label: 'Transactions',
                route: '/transactions',
              ),
              _buildNavItem(
                context: context,
                tab: MpmNavTab.more,
                icon: Icons.apps_outlined,
                activeIcon: Icons.apps_rounded,
                label: 'More',
                route: '/settings',
                onTap: () => _showMoreBottomSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required MpmNavTab tab,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required String route,
    VoidCallback? onTap,
  }) {
    final isActive = currentTab == tab;

    return Expanded(
      child: InkWell(
        onTap: onTap ??
            () {
              if (!isActive) {
                context.go(route);
              }
            },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.secondaryFixed.withValues(alpha: 0.6)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(
                  isActive ? activeIcon : icon,
                  size: 20,
                  color: isActive ? AppColors.navyContainer : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.labelSm(
                color: isActive ? AppColors.navyContainer : AppColors.textSecondary,
              ).copyWith(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Management Hub',
                      style: AppTypography.headlineSm(color: AppColors.navyContainer),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMoreTile(
                  context: ctx,
                  icon: Icons.payments_outlined,
                  title: 'Payment Settlements',
                  subtitle: 'History of cash and UPI receipts',
                  route: '/payments',
                ),
                _buildMoreTile(
                  context: ctx,
                  icon: Icons.badge_outlined,
                  title: 'Salesmen & Targets',
                  subtitle: 'Performance, collections & territory',
                  route: '/salesmen',
                ),
                _buildMoreTile(
                  context: ctx,
                  icon: Icons.bar_chart_rounded,
                  title: 'Financial Reports',
                  subtitle: 'Ledger exports, GST statements & audit',
                  route: '/reports',
                ),
                _buildMoreTile(
                  context: ctx,
                  icon: Icons.history_edu_outlined,
                  title: 'Audit Logs',
                  subtitle: 'Immutable record of operations',
                  route: '/logs',
                ),
                _buildMoreTile(
                  context: ctx,
                  icon: Icons.settings_outlined,
                  title: 'Business Settings',
                  subtitle: 'Profile, print setup & preferences',
                  route: '/settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoreTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.navyContainer, size: 20),
      ),
      title: Text(title, style: AppTypography.labelLg(color: AppColors.navyContainer)),
      subtitle: Text(subtitle, style: AppTypography.bodySm(color: AppColors.textMuted)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: () {
        Navigator.pop(context);
        context.push(route);
      },
    );
  }
}
