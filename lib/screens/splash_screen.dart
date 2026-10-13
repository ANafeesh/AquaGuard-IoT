import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../constants/app_colors.dart';
import '../core/animations/ripple_pulse.dart';
import '../core/animations/water_wave_widget.dart';
import '../providers/repository_providers.dart';
import '../services/local_storage_service.dart';
import 'onboarding_screen.dart';
import 'auth/login_screen.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _bubbleController;
  late AnimationController _introController;
  late AnimationController _floatingController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  Timer? _navTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // 1. Continuous Rising Water Droplet Dots Animation (Small dots going to top)
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // 2. Entrance Fade & Scale Controller
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeIn,
      ),
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: Curves.easeOutBack,
      ),
    );

    // 3. Ambient Floating Motion Controller
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _introController.forward();

    // Auto navigate after 2.5 seconds (or tap anywhere to skip)
    _navTimer = Timer(const Duration(milliseconds: 2500), _navigateToNext);
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _introController.dispose();
    _floatingController.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  void _navigateToNext() {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;
    _navTimer?.cancel();

    final storage = LocalStorageService.instance;
    final hasCompletedOnboarding =
        storage.getBool('hasCompletedOnboarding', defaultValue: false);
    final currentUser = ref.read(authRepositoryProvider).getCurrentUser();

    Widget targetScreen;
    if (!hasCompletedOnboarding) {
      targetScreen = const OnboardingScreen();
    } else if (currentUser != null) {
      targetScreen = const MainNavigationScreen();
    } else {
      targetScreen = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => targetScreen,
        transitionsBuilder: (context, anim1, anim2, child) {
          final fade = CurvedAnimation(parent: anim1, curve: Curves.easeInOut);
          final scale = Tween<double>(begin: 0.98, end: 1.0).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: GestureDetector(
          onTap: _navigateToNext, // Tap anywhere to continue immediately
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0284C7),
                  Color(0xFF0369A1),
                ],
              ),
            ),
            child: Stack(
              children: [
                // 1. SMALL DOT-DOT WATER GOING TO TOP ANIMATION (Rising bubbles)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _bubbleController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _WaterDropletDotsPainter(
                          progress: _bubbleController.value,
                        ),
                      );
                    },
                  ),
                ),

                // 2. Subtle fluid wave shimmer at the bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: WaterWaveWidget(
                    height: 110,
                    primaryColor: Colors.white.withValues(alpha: 0.12),
                    secondaryColor: AppColors.teal.withValues(alpha: 0.18),
                    amplitude: 10.0,
                    speed: const Duration(milliseconds: 3200),
                    showSurfaceGlow: true,
                  ),
                ),

                // 3. Main Splash Layout
                SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Tag (Prototype Mode)
                      Padding(
                        padding: const EdgeInsets.only(top: 24.0),
                        child: AppConfig.useMockData
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'PROTOTYPE MODE',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : const SizedBox(height: 28),
                      ),

                      // Center Hero Logo & Titles
                      AnimatedBuilder(
                        animation: Listenable.merge(
                            [_introController, _floatingController]),
                        builder: (context, child) {
                          final floatOffset = math.sin(
                                  _floatingController.value * 2 * math.pi) *
                              4.5;
                          return Opacity(
                            opacity: _logoFade.value,
                            child: Transform.translate(
                              offset: Offset(0, floatOffset),
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Custom Droplet Emblem with Ripple Waves
                            RipplePulse(
                              size: 190,
                              color: Colors.white.withValues(alpha: 0.35),
                              ringCount: 3,
                              duration: const Duration(milliseconds: 2200),
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      color: AppColors.primaryAqua
                                          .withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Droplet base
                                    const Icon(
                                      Icons.water_drop_rounded,
                                      size: 58,
                                      color: AppColors.primaryAqua,
                                    ),
                                    // Small sensors overlay inside
                                    Positioned(
                                      bottom: 28,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryDeepOcean,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.sensors_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // AquaGuard Title
                            const Text(
                              'AquaGuard',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              'Smart Water Quality Monitoring',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Tagline
                      Padding(
                        padding: const EdgeInsets.only(bottom: 32.0),
                        child: Column(
                          children: [
                            Text(
                              'Monitor  •  Understand  •  Protect',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.85),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tap anywhere to continue',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter rendering realistic small dot-dot water bubbles going to the top
class _WaterDropletDotsPainter extends CustomPainter {
  final double progress;

  _WaterDropletDotsPainter({required this.progress});

  // Comprehensive set of small water droplet dot particles distributed across the screen
  static const List<({double x, double speed, double size, double drift, double offset, double alpha})>
      _dots = [
    (x: 0.08, speed: 1.0, size: 3.5, drift: 8.0, offset: 0.02, alpha: 0.55),
    (x: 0.14, speed: 1.25, size: 4.8, drift: -10.0, offset: 0.18, alpha: 0.65),
    (x: 0.18, speed: 0.85, size: 2.5, drift: 6.0, offset: 0.45, alpha: 0.50),
    (x: 0.23, speed: 1.15, size: 5.5, drift: 12.0, offset: 0.62, alpha: 0.70),
    (x: 0.29, speed: 0.95, size: 3.0, drift: -7.0, offset: 0.31, alpha: 0.55),
    (x: 0.34, speed: 1.35, size: 4.2, drift: 9.0, offset: 0.82, alpha: 0.60),
    (x: 0.39, speed: 0.75, size: 2.2, drift: -5.0, offset: 0.12, alpha: 0.45),
    (x: 0.44, speed: 1.1, size: 6.2, drift: 11.0, offset: 0.54, alpha: 0.75),
    (x: 0.48, speed: 0.9, size: 3.2, drift: -8.0, offset: 0.77, alpha: 0.55),
    (x: 0.53, speed: 1.3, size: 5.0, drift: 10.0, offset: 0.25, alpha: 0.68),
    (x: 0.58, speed: 0.8, size: 2.8, drift: -6.0, offset: 0.68, alpha: 0.50),
    (x: 0.63, speed: 1.2, size: 4.5, drift: 8.0, offset: 0.41, alpha: 0.62),
    (x: 0.67, speed: 1.05, size: 3.0, drift: -9.0, offset: 0.88, alpha: 0.55),
    (x: 0.72, speed: 1.4, size: 5.8, drift: 13.0, offset: 0.15, alpha: 0.72),
    (x: 0.77, speed: 0.85, size: 2.4, drift: -5.0, offset: 0.59, alpha: 0.48),
    (x: 0.82, speed: 1.15, size: 4.0, drift: 7.0, offset: 0.36, alpha: 0.60),
    (x: 0.87, speed: 0.95, size: 6.0, drift: -11.0, offset: 0.72, alpha: 0.70),
    (x: 0.92, speed: 1.25, size: 3.2, drift: 8.0, offset: 0.05, alpha: 0.55),
    (x: 0.96, speed: 0.78, size: 2.6, drift: -6.0, offset: 0.49, alpha: 0.50),
    (x: 0.11, speed: 1.1, size: 3.8, drift: 7.0, offset: 0.93, alpha: 0.58),
    (x: 0.26, speed: 0.88, size: 2.5, drift: -4.0, offset: 0.08, alpha: 0.45),
    (x: 0.41, speed: 1.22, size: 4.6, drift: 9.0, offset: 0.66, alpha: 0.64),
    (x: 0.56, speed: 0.92, size: 3.4, drift: -7.0, offset: 0.01, alpha: 0.55),
    (x: 0.74, speed: 1.32, size: 5.2, drift: 10.0, offset: 0.84, alpha: 0.68),
    (x: 0.85, speed: 0.82, size: 2.8, drift: -5.0, offset: 0.22, alpha: 0.50),
    (x: 0.61, speed: 1.18, size: 4.0, drift: 8.0, offset: 0.51, alpha: 0.60),
    (x: 0.36, speed: 1.05, size: 3.6, drift: -8.0, offset: 0.43, alpha: 0.56),
    (x: 0.16, speed: 1.28, size: 5.0, drift: 11.0, offset: 0.79, alpha: 0.66),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final dot in _dots) {
      final itemProgress = ((progress * dot.speed) + dot.offset) % 1.0;

      // Starts below screen and travels all the way past the top
      final y = (size.height + 40) * (1.0 - itemProgress) - 20;

      // Gentle sine wave horizontal drift
      final x = (size.width * dot.x) +
          math.sin((itemProgress * 2 * math.pi) + (dot.offset * 10)) *
              dot.drift;

      // Gentle fade in at bottom, fade out at top
      final fadeFactor = math.sin(itemProgress * math.pi);
      final alpha = (dot.alpha * fadeFactor).clamp(0.0, 1.0);

      // 1. Water bubble body (translucent glowing dot)
      final bodyPaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.55)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), dot.size, bodyPaint);

      // 2. Crisp bubble rim/border for water droplet appearance
      final rimPaint = Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9;
      canvas.drawCircle(Offset(x, y), dot.size, rimPaint);

      // 3. Tiny specular highlight gleam on bubbles size >= 3.8
      if (dot.size >= 3.8) {
        final gleamPaint = Paint()
          ..color = Colors.white.withValues(alpha: alpha * 0.95)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
          Offset(x - dot.size * 0.32, y - dot.size * 0.32),
          dot.size * 0.28,
          gleamPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaterDropletDotsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
