import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  AppColors.shadowLevel2,
                  AppColors.shadowLevel2Ambient,
                ],
              ),
              child: Center(
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
            const SizedBox(height: 24),
            Text(
              'MPM CONNECT',
              style: AppTypography.displayLg(color: AppColors.navyDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Customer Credit & Collection Management',
              style: AppTypography.bodyMd(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.navyPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
