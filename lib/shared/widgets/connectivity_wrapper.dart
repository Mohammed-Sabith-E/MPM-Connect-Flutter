import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/connectivity_provider.dart';
import '../screens/no_internet_screen.dart';

/// Wraps application or screen scaffold to provide a persistent, non-intrusive
/// offline indicator when internet connectivity is lost, allowing users to view cached records
/// while offering a 1-tap pathway to the animated diagnostics screen.
class ConnectivityWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectivityWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends ConsumerState<ConnectivityWrapper> {
  bool _wasOffline = false;
  bool _showReconnectedBanner = false;

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);

    // Track reconnection transition
    ref.listen(isOnlineProvider, (previous, current) {
      if (previous == false && current == true) {
        setState(() {
          _wasOffline = true;
          _showReconnectedBanner = true;
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _showReconnectedBanner = false);
          }
        });
      }
    });

    if (!isOnline) {
      return const Directionality(
        textDirection: TextDirection.ltr,
        child: NoInternetScreen(showOfflineModeButton: false),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,

          // Reconnected Micro-Banner (Auto-dismisses in 3 seconds)
          if (_showReconnectedBanner && _wasOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppColors.navyPrimary.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.emeraldSuccess, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emeraldSuccess.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wifi_rounded,
                            color: AppColors.emeraldSuccess,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Back online • Live ledger sync active',
                              style: AppTypography.labelSm(color: Colors.white).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
