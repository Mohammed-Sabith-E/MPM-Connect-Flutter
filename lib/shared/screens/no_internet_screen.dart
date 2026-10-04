import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/connectivity_provider.dart';
import '../../core/utils/app_toast.dart';

/// Screen rendered when there is no internet connection, perfectly reproducing
/// the Stitch MPM Connect design specification:
/// - Playful springing Wi-Fi signal arcs
/// - Amber magnetic slash barrier with sparks and shockwave rings
/// - Central dark hub character mascot with cute eyes, blushes, and smile
/// - Bold "Oops!" heading & "No internet connection" subtitle
/// - Pill-shaped "Try Again" CTA button with animated refresh feedback
class NoInternetScreen extends ConsumerStatefulWidget {
  /// If true, allows continuing in cached offline mode (optional, defaults to false)
  final bool showOfflineModeButton;

  /// Optional callback invoked when connection is restored or retry is pressed
  final VoidCallback? onRetry;

  const NoInternetScreen({
    super.key,
    this.showOfflineModeButton = false,
    this.onRetry,
  });

  @override
  ConsumerState<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends ConsumerState<NoInternetScreen>
    with TickerProviderStateMixin {
  late final AnimationController _springController;
  late final AnimationController _eyesController;
  late final AnimationController _spinController;

  late final Animation<double> _springAnimation;
  late final Animation<double> _eyesAnimation;

  bool _isChecking = false;

  @override
  void initState() {
    super.initState();

    // Gentle spring/float for signal arcs
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _springAnimation = Tween<double>(begin: -4.0, end: 4.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeInOut),
    );

    // Curious eyes glancing left and right
    _eyesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);

    _eyesAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _eyesController, curve: Curves.easeInOutSine),
    );

    // Refresh icon spin
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    _eyesController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);
    _spinController.repeat();
    HapticFeedback.lightImpact();
    widget.onRetry?.call();

    final service = ref.read(networkConnectivityServiceProvider);
    final isOnline = await service.checkConnection();

    // Small delay to allow user to see the checking state as designed in Stitch
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    _spinController.stop();
    _spinController.reset();
    setState(() => _isChecking = false);

    if (isOnline) {
      HapticFeedback.mediumImpact();
      AppToast.success('Internet connection restored!');
      if (context.canPop()) {
        context.pop();
      }
    } else {
      HapticFeedback.heavyImpact();
      AppToast.error('Still offline. Please check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Auto-dismiss when connection restored
    ref.listen(isOnlineProvider, (previous, isOnline) {
      if (isOnline && mounted) {
        widget.onRetry?.call();
        if (context.canPop()) {
          context.pop();
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mascot Container with Ambient Glow
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient golden glow backdrop
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFFDCC3).withValues(alpha: 0.6),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFE932C).withValues(alpha: 0.22),
                              blurRadius: 36,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),

                      // Animated Stitch Mascot
                      AnimatedBuilder(
                        animation: Listenable.merge([_springAnimation, _eyesAnimation]),
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _springAnimation.value),
                            child: CustomPaint(
                              size: const Size(190, 190),
                              painter: _StitchMascotPainter(
                                eyeShift: _eyesAnimation.value,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Headline "Oops!"
                Text(
                  'Oops!',
                  style: AppTypography.displayLg(color: const Color(0xFF00162D)).copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle "No internet connection"
                Text(
                  'No internet connection',
                  style: AppTypography.bodyMd(color: const Color(0xFF43474D)).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // Primary Action Button: Exact Stitch Pill CTA
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isChecking ? null : _handleRetry,
                    borderRadius: BorderRadius.circular(9999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2B48),
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F2B48).withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RotationTransition(
                            turns: _spinController,
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: Color(0xFFFFDCC3),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _isChecking ? 'Checking...' : 'Try Again',
                            style: AppTypography.labelLg(color: Colors.white).copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (widget.showOfflineModeButton) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                    child: Text(
                      'Continue in Cached Offline Mode',
                      style: AppTypography.bodySm(color: AppColors.textSecondary).copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stitch Wi-Fi Mascot Painter ────────────────────────────────────────────
class _StitchMascotPainter extends CustomPainter {
  final double eyeShift;

  _StitchMascotPainter({required this.eyeShift});

  @override
  void paint(Canvas canvas, Size size) {
    // Canvas maps to 180x180 Stitch SVG viewBox
    final scale = size.width / 180.0;
    canvas.save();
    canvas.scale(scale, scale);

    const navyColor = Color(0xFF0F2B48);
    const amberColor = Color(0xFFFE932C);

    // 1. SIGNAL ARCS
    final arcPaint = Paint()
      ..color = navyColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Outer Signal Arc: M 32 64 A 76 76 0 0 1 148 64
    arcPaint.strokeWidth = 8.5;
    final outerPath = Path()
      ..moveTo(32, 64)
      ..arcToPoint(const Offset(148, 64), radius: const Radius.circular(76));
    canvas.drawPath(outerPath, arcPaint);

    // Mid Signal Arc: M 52 83 A 50 50 0 0 1 128 83
    arcPaint.strokeWidth = 8.5;
    final midPath = Path()
      ..moveTo(52, 83)
      ..arcToPoint(const Offset(128, 83), radius: const Radius.circular(50));
    canvas.drawPath(midPath, arcPaint);

    // Inner Signal Arc: M 72 102 A 24 24 0 0 1 108 102
    arcPaint.strokeWidth = 7.5;
    final innerPath = Path()
      ..moveTo(72, 102)
      ..arcToPoint(const Offset(108, 102), radius: const Radius.circular(24));
    canvas.drawPath(innerPath, arcPaint);

    // 2. SHOCKWAVE RINGS
    final shockwavePaint = Paint()
      ..color = amberColor.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(const Offset(78, 80), 16, shockwavePaint);
    canvas.drawCircle(const Offset(114, 112), 12, shockwavePaint);

    // 3. DIAGONAL BARRIER SLASH
    // Soft outer accent glow line: M 40 38 L 140 142
    final slashGlowPaint = Paint()
      ..color = amberColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(40, 38), const Offset(140, 142), slashGlowPaint);

    // Core dashed barrier line: M 42 40 L 138 140
    final slashCorePaint = Paint()
      ..color = amberColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
      ..strokeCap = StrokeCap.round;

    _drawDashedLine(
      canvas,
      const Offset(42, 40),
      const Offset(138, 140),
      dashLength: 10,
      gapLength: 7,
      paint: slashCorePaint,
    );

    // 4. KINETIC SPARKS & MICRO SPECKS
    final sparkPaint = Paint()..color = amberColor;
    canvas.drawCircle(const Offset(66, 68), 3.5, sparkPaint);

    final sparklePath1 = Path()
      ..moveTo(62, 60)
      ..lineTo(65, 65)
      ..lineTo(70, 63)
      ..close();
    canvas.drawPath(sparklePath1, Paint()..color = const Color(0xFFF59E0B));

    canvas.drawCircle(const Offset(108, 104), 3.0, sparkPaint);

    final sparkPolygon = Path()
      ..moveTo(113, 99)
      ..lineTo(116, 104)
      ..lineTo(120, 101)
      ..lineTo(116, 108)
      ..lineTo(110, 105)
      ..close();
    canvas.drawPath(sparkPolygon, Paint()..color = const Color(0xFFFFDCC3));

    // Ambient floating micro gold specks
    canvas.drawCircle(
      const Offset(148, 48),
      2.5,
      Paint()..color = amberColor.withValues(alpha: 0.6),
    );
    canvas.drawCircle(
      const Offset(36, 120),
      2.5,
      Paint()..color = amberColor.withValues(alpha: 0.5),
    );

    // 5. CENTRAL CHARACTER HUB (Mascot dot with cute face)
    // Soft Base Drop Glow
    canvas.drawCircle(
      const Offset(90, 132),
      26,
      Paint()..color = navyColor.withValues(alpha: 0.1),
    );

    // Hub Body
    canvas.drawCircle(
      const Offset(90, 130),
      22,
      Paint()..color = navyColor,
    );

    // Expressive Eyes (with slight horizontal glance shift)
    final eyeOffset = Offset(eyeShift, 0);

    // Left Eye & Pupil
    canvas.drawCircle(const Offset(82, 128) + eyeOffset, 3.2, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(83.5, 126.8) + eyeOffset, 1.4, Paint()..color = navyColor);

    // Right Eye & Pupil
    canvas.drawCircle(const Offset(98, 128) + eyeOffset, 3.2, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(99.5, 126.8) + eyeOffset, 1.4, Paint()..color = navyColor);

    // Warm Rosy Blushes
    final blushPaint = Paint()..color = amberColor.withValues(alpha: 0.55);
    canvas.drawCircle(const Offset(76, 133), 2.5, blushPaint);
    canvas.drawCircle(const Offset(104, 133), 2.5, blushPaint);

    // Expressive Cute Mouth
    final mouthPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(87, 136)
      ..quadraticBezierTo(90, 138.5, 93, 136);
    canvas.drawPath(mouthPath, mouthPaint);

    canvas.restore();
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end, {
    required double dashLength,
    required double gapLength,
    required Paint paint,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final totalDistance = math.sqrt(dx * dx + dy * dy);
    final unitX = dx / totalDistance;
    final unitY = dy / totalDistance;

    double currentDistance = 0.0;
    while (currentDistance < totalDistance) {
      final currentDashLength = math.min(dashLength, totalDistance - currentDistance);
      final p1 = Offset(
        start.dx + unitX * currentDistance,
        start.dy + unitY * currentDistance,
      );
      final p2 = Offset(
        p1.dx + unitX * currentDashLength,
        p1.dy + unitY * currentDashLength,
      );
      canvas.drawLine(p1, p2, paint);
      currentDistance += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(_StitchMascotPainter oldDelegate) =>
      oldDelegate.eyeShift != eyeShift;
}
