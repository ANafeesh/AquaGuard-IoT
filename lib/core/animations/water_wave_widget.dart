import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A high-performance, fluid animated water wave widget.
/// Renders two overlapping sinusoidal wave layers with customizable speeds,
/// amplitudes, and colors to create an immersive liquid surface effect.
class WaterWaveWidget extends StatefulWidget {
  final double height;
  final Color primaryColor;
  final Color secondaryColor;
  final double amplitude;
  final double frequency;
  final Duration speed;
  final bool showSurfaceGlow;

  const WaterWaveWidget({
    super.key,
    this.height = 120,
    this.primaryColor = const Color(0xFF0EA5E9),
    this.secondaryColor = const Color(0xFF0D9488),
    this.amplitude = 12.0,
    this.frequency = 1.2,
    this.speed = const Duration(milliseconds: 3200),
    this.showSurfaceGlow = true,
  });

  @override
  State<WaterWaveWidget> createState() => _WaterWaveWidgetState();
}

class _WaterWaveWidgetState extends State<WaterWaveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.speed,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _DualWavePainter(
            animationValue: _controller.value,
            primaryColor: widget.primaryColor,
            secondaryColor: widget.secondaryColor,
            amplitude: widget.amplitude,
            frequency: widget.frequency,
            showGlow: widget.showSurfaceGlow,
          ),
        );
      },
    );
  }
}

class _DualWavePainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;
  final double amplitude;
  final double frequency;
  final bool showGlow;

  _DualWavePainter({
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
    required this.amplitude,
    required this.frequency,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final baseWaterLevel = height * 0.45;

    // 1. Draw Secondary / Background Wave (Offset by 0.5 pi, slightly slower phase)
    final backPath = Path();
    backPath.moveTo(0, height);
    backPath.lineTo(0, baseWaterLevel);

    final backPhase = animationValue * 2 * math.pi;
    for (double x = 0; x <= width; x += 3) {
      final y = baseWaterLevel +
          math.sin((x / width * 2 * math.pi * frequency) + backPhase) *
              (amplitude * 0.85) +
          math.cos((x / width * math.pi * 0.7) + backPhase * 0.5) * 4.0;
      backPath.lineTo(x, y);
    }
    backPath.lineTo(width, height);
    backPath.close();

    final backPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          secondaryColor.withValues(alpha: 0.35),
          secondaryColor.withValues(alpha: 0.8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(backPath, backPaint);

    // 2. Draw Primary / Foreground Wave (Leading phase)
    final frontPath = Path();
    frontPath.moveTo(0, height);
    frontPath.lineTo(0, baseWaterLevel + 8);

    final frontPhase = (animationValue * 2 * math.pi) + math.pi * 0.75;
    for (double x = 0; x <= width; x += 3) {
      final y = baseWaterLevel + 8 +
          math.sin((x / width * 2 * math.pi * frequency) + frontPhase) *
              amplitude +
          math.sin((x / width * math.pi * 1.5) + frontPhase * 0.6) * 3.0;
      frontPath.lineTo(x, y);
    }
    frontPath.lineTo(width, height);
    frontPath.close();

    final frontPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withValues(alpha: 0.75),
          primaryColor.withValues(alpha: 0.95),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(frontPath, frontPaint);

    // 3. Highlight Glow on wavecrest
    if (showGlow) {
      final crestPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;

      final crestPath = Path();
      bool first = true;
      for (double x = 0; x <= width; x += 6) {
        final y = baseWaterLevel + 8 +
            math.sin((x / width * 2 * math.pi * frequency) + frontPhase) *
                amplitude +
            math.sin((x / width * math.pi * 1.5) + frontPhase * 0.6) * 3.0;
        if (first) {
          crestPath.moveTo(x, y);
          first = false;
        } else {
          crestPath.lineTo(x, y);
        }
      }
      canvas.drawPath(crestPath, crestPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DualWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
