import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../constants/app_colors.dart';
import '../core/animations/water_wave_widget.dart';
import '../core/animations/ripple_pulse.dart';
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
  late AnimationController _introController;
  late AnimationController _floatingController;
  late AnimationController _progressController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  Timer? _navTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // 1. Entrance Choreography Controller
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // 2. Ambient Floating / Breathing Motion Controller
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    // 3. Startup Progress Indicator Controller (syncs with 2.8s auto-nav)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2700),
    )..forward();

    _logoScale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.3, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeIn),
      ),
    );

    _introController.forward();

    // Auto navigate after 2.8 seconds
    _navTimer = Timer(const Duration(milliseconds: 2800), _navigateToNext);
  }

  @override
  void dispose() {
    _introController.dispose();
    _floatingController.dispose();
    _progressController.dispose();
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
          final scale = Tween<double>(begin: 0.96, end: 1.0).animate(
            CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.dark, // for iOS: renders white text/icons on ocean blue
        statusBarIconBrightness: Brightness.light, // for Android: renders white icons
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryDeepOcean,
        body: GestureDetector(
          onTap: _navigateToNext, // Tap anywhere to proceed
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          child: Stack(
            children: [
              // 1. Ambient Floating Water Bubble Particle Layer
              const Positioned.fill(
                child: _AmbientBubbleParticles(),
              ),

              // 2. Animated Fluid Water Wave at Bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: WaterWaveWidget(
                  height: 140,
                  primaryColor: Colors.white.withValues(alpha: 0.18),
                  secondaryColor: AppColors.teal.withValues(alpha: 0.25),
                  amplitude: 14.0,
                  speed: const Duration(milliseconds: 3600),
                  showSurfaceGlow: true,
                ),
              ),

              // 3. Foreground Interactive UI
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Prototype Tag
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: AppConfig.useMockData
                          ? FadeTransition(
                              opacity: _textFade,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.25),
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
                              ),
                            )
                          : const SizedBox(height: 28),
                    ),

                    // Center Animated Hero Droplet & Typography
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Water Droplet with Concentric Water Ripples & Floating Hover
                        AnimatedBuilder(
                          animation: Listenable.merge(
                              [_introController, _floatingController]),
                          builder: (context, child) {
                            final floatOffset =
                                math.sin(_floatingController.value * 2 * math.pi) *
                                    5.0;
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
                          child: RipplePulse(
                            size: 200,
                            color: Colors.white.withValues(alpha: 0.45),
                            ringCount: 3,
                            duration: const Duration(milliseconds: 2200),
                            child: Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: AppColors.primaryAqua
                                        .withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    spreadRadius: 4,
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
                                  // Sensor shield icon
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
                        ),
                        const SizedBox(height: 20),

                        // Animated Titles with Slide and Fade
                        AnimatedBuilder(
                          animation: _introController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _textFade.value,
                              child: SlideTransition(
                                position: _textSlide,
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              // Title
                              const Text(
                                'AquaGuard',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.8,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 12,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
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
                                  color: Colors.white.withValues(alpha: 0.92),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 22),

                              // Animated Loading Bar with Progress
                              Container(
                                width: 140,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: AnimatedBuilder(
                                  animation: _progressController,
                                  builder: (context, _) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: _progressController.value,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.white
                                                    .withValues(alpha: 0.7),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bottom Tagline & Tap Hint
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28.0),
                      child: FadeTransition(
                        opacity: _textFade,
                        child: Column(
                          children: [
                            Text(
                              'Monitor  •  Understand  •  Protect',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.88),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.7),
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

/// Gentle ambient rising bubble particles in the background
class _AmbientBubbleParticles extends StatefulWidget {
  const _AmbientBubbleParticles();

  @override
  State<_AmbientBubbleParticles> createState() =>
      _AmbientBubbleParticlesState();
}

class _AmbientBubbleParticlesState extends State<_AmbientBubbleParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _bubbleController;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bubbleController,
      builder: (context, _) {
        return CustomPaint(
          painter: _BubblePainter(progress: _bubbleController.value),
        );
      },
    );
  }
}

class _BubblePainter extends CustomPainter {
  final double progress;

  _BubblePainter({required this.progress});

  // Fixed bubble seeds for consistent beautiful layout
  static final List<({double x, double speed, double size, double drift})>
      _bubbles = [
    (x: 0.15, speed: 1.0, size: 6.0, drift: 12.0),
    (x: 0.28, speed: 0.75, size: 4.5, drift: -8.0),
    (x: 0.42, speed: 1.2, size: 7.0, drift: 14.0),
    (x: 0.65, speed: 0.85, size: 5.0, drift: -10.0),
    (x: 0.78, speed: 1.1, size: 8.0, drift: 16.0),
    (x: 0.88, speed: 0.65, size: 4.0, drift: -6.0),
    (x: 0.35, speed: 0.95, size: 5.5, drift: 10.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _bubbles) {
      final itemProgress = (progress * b.speed) % 1.0;
      final y = size.height * (1.0 - itemProgress);
      final x = (size.width * b.x) +
          math.sin(itemProgress * 2 * math.pi) * b.drift;

      final opacity = math.sin(itemProgress * math.pi) * 0.28;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 0.3))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), b.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
