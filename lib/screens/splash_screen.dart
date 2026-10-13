import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../constants/app_colors.dart';
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
  late AnimationController _waterRiseController;
  late AnimationController _waveLoopController;
  late AnimationController _contentFadeController;
  late AnimationController _floatingController;

  late Animation<double> _waterRiseAnimation;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _textSlide;

  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    // 1. Water Rising from Bottom to Top (1.9 seconds total)
    _waterRiseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    _waterRiseAnimation = CurvedAnimation(
      parent: _waterRiseController,
      curve: Curves.easeInOutCubic,
    );

    // 2. Continuous Wave Oscillation
    _waveLoopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // 3. Floating / Breathing motion for the central emblem
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // 4. Content entrance choreography
    _contentFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentFadeController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentFadeController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentFadeController,
        curve: const Interval(0.2, 0.9, curve: Curves.easeOutCubic),
      ),
    );

    _contentFadeController.forward();
    _waterRiseController.forward();

    // Automatically navigate when water finishes rising to top
    _waterRiseController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNext();
      }
    });
  }

  @override
  void dispose() {
    _waterRiseController.dispose();
    _waveLoopController.dispose();
    _contentFadeController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;

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
        backgroundColor: const Color(0xFF071B2F),
        body: GestureDetector(
          onTap: _navigateToNext, // Instant tap to skip
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // 1. Base Gradient Background (Deep oceanic blue)
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF03224C),
                      Color(0xFF071B2F),
                      Color(0xFF021323),
                    ],
                  ),
                ),
              ),

              // 2. Rising Water Wave Layer (Floods from bottom to top!)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _waterRiseAnimation,
                    _waveLoopController,
                  ]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _RisingWaterPainter(
                        fillProgress: _waterRiseAnimation.value,
                        wavePhase: _waveLoopController.value * 2 * math.pi,
                      ),
                    );
                  },
                ),
              ),

              // 3. Ambient Rising Bubbles
              const Positioned.fill(
                child: _AmbientBubbleParticles(),
              ),

              // 4. Foreground Content Layer
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Prototype Tag
                    Padding(
                      padding: const EdgeInsets.only(top: 18.0),
                      child: AppConfig.useMockData
                          ? FadeTransition(
                              opacity: _logoFade,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.sensors_rounded,
                                      size: 13,
                                      color: AppColors.primaryAqua,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'PROTOTYPE MODE',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: Colors.white,
                                        fontSize: 11,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(height: 28),
                    ),

                    // Central Emblem & Typography
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Floating Hero Water Droplet
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _contentFadeController,
                            _floatingController,
                          ]),
                          builder: (context, child) {
                            final floatOffset = math.sin(
                                    _floatingController.value * 2 * math.pi) *
                                4.0;
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
                            size: 210,
                            color: Colors.white.withValues(alpha: 0.4),
                            ringCount: 3,
                            duration: const Duration(milliseconds: 2000),
                            child: Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.28),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                  BoxShadow(
                                    color: AppColors.primaryAqua
                                        .withValues(alpha: 0.45),
                                    blurRadius: 22,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Base Droplet Icon
                                  const Icon(
                                    Icons.water_drop_rounded,
                                    size: 60,
                                    color: AppColors.primaryAqua,
                                  ),
                                  // Sensors badge overlay
                                  Positioned(
                                    bottom: 29,
                                    child: Container(
                                      padding: const EdgeInsets.all(4.5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryDeepOcean,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.8,
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
                        const SizedBox(height: 24),

                        // Title & Subtitle with upward slide
                        SlideTransition(
                          position: _textSlide,
                          child: FadeTransition(
                            opacity: _logoFade,
                            child: Column(
                              children: [
                                const Text(
                                  'AquaGuard',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 35,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.6,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black38,
                                        blurRadius: 16,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Smart Water Quality Monitoring',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Bottom Tagline & Liquid Progress
                    Padding(
                      padding: const EdgeInsets.only(bottom: 28.0),
                      child: Column(
                        children: [
                          // Animated water level percentage bar
                          AnimatedBuilder(
                            animation: _waterRiseAnimation,
                            builder: (context, _) {
                              final percent =
                                  (_waterRiseAnimation.value * 100).toInt();
                              return Container(
                                width: 140,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor:
                                      _waterRiseAnimation.value.clamp(0.05, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppColors.primaryAqua,
                                          AppColors.teal,
                                          Colors.white,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primaryAqua
                                              .withValues(alpha: 0.6),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Monitor  •  Understand  •  Protect',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAqua,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryAqua
                                          .withValues(alpha: 0.8),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Tap anywhere to start',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  letterSpacing: 0.2,
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
    );
  }
}

/// Custom painter that renders animated water rising from bottom to top!
class _RisingWaterPainter extends CustomPainter {
  final double fillProgress; // 0.0 (empty / at bottom) -> 1.0 (submerged / at top)
  final double wavePhase;

  _RisingWaterPainter({
    required this.fillProgress,
    required this.wavePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Water level Y coordinate starts at height (bottom) and rises to -40 (past top)
    final targetY = height - (height + 60) * fillProgress;

    // 1. Draw Secondary Wave Layer (Background, deeper teal, offset phase)
    final backPath = Path();
    backPath.moveTo(0, height);
    backPath.lineTo(0, targetY + 14);

    final backAmplitude = 14.0 * (1.0 - (fillProgress - 0.5).abs() * 0.4);
    for (double x = 0; x <= width; x += 3) {
      final y = targetY +
          14 +
          math.sin((x / width * 2.5 * math.pi) + wavePhase + (math.pi / 2)) *
              backAmplitude;
      backPath.lineTo(x, y);
    }
    backPath.lineTo(width, height);
    backPath.close();

    final backPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0284C7).withValues(alpha: 0.45),
          const Color(0xFF0369A1).withValues(alpha: 0.65),
          const Color(0xFF0F172A).withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromLTWH(0, targetY, width, height - targetY));

    canvas.drawPath(backPath, backPaint);

    // 2. Draw Primary Wave Layer (Foreground, vibrant aqua glow)
    final forePath = Path();
    forePath.moveTo(0, height);
    forePath.lineTo(0, targetY);

    final foreAmplitude = 16.0 * (1.0 - (fillProgress - 0.5).abs() * 0.4);
    for (double x = 0; x <= width; x += 3) {
      final y = targetY +
          math.sin((x / width * 2.8 * math.pi) - wavePhase) * foreAmplitude +
          math.cos((x / width * 1.5 * math.pi) + wavePhase * 0.6) * 4.0;
      forePath.lineTo(x, y);
    }
    forePath.lineTo(width, height);
    forePath.close();

    final forePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF0EA5E9).withValues(alpha: 0.72),
          const Color(0xFF0284C7).withValues(alpha: 0.85),
          const Color(0xFF034A75).withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromLTWH(0, targetY, width, height - targetY));

    canvas.drawPath(forePath, forePaint);

    // 3. Highlight Glow Crest Line
    final crestPath = Path();
    for (double x = 0; x <= width; x += 3) {
      final y = targetY +
          math.sin((x / width * 2.8 * math.pi) - wavePhase) * foreAmplitude +
          math.cos((x / width * 1.5 * math.pi) + wavePhase * 0.6) * 4.0;
      if (x == 0) {
        crestPath.moveTo(x, y);
      } else {
        crestPath.lineTo(x, y);
      }
    }

    final crestPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(crestPath, crestPaint);
  }

  @override
  bool shouldRepaint(covariant _RisingWaterPainter oldDelegate) {
    return oldDelegate.fillProgress != fillProgress ||
        oldDelegate.wavePhase != wavePhase;
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
      duration: const Duration(seconds: 5),
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
    (x: 0.12, speed: 1.0, size: 5.5, drift: 12.0),
    (x: 0.24, speed: 0.75, size: 4.0, drift: -8.0),
    (x: 0.38, speed: 1.25, size: 6.5, drift: 14.0),
    (x: 0.52, speed: 0.85, size: 4.8, drift: -10.0),
    (x: 0.68, speed: 1.1, size: 7.2, drift: 16.0),
    (x: 0.82, speed: 0.7, size: 4.2, drift: -6.0),
    (x: 0.90, speed: 1.0, size: 5.8, drift: 10.0),
    (x: 0.44, speed: 0.95, size: 3.5, drift: -12.0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _bubbles) {
      final itemProgress = (progress * b.speed) % 1.0;
      final y = size.height * (1.0 - itemProgress);
      final x = (size.width * b.x) +
          math.sin(itemProgress * 2 * math.pi) * b.drift;

      final opacity = math.sin(itemProgress * math.pi) * 0.45;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 0.45))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), b.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
