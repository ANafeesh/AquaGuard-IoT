import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated concentric water ripples expanding outwards from a center point.
/// Perfect for water drop impact animations, radar scanning, and IoT active status.
class RipplePulse extends StatefulWidget {
  final double size;
  final Color color;
  final int ringCount;
  final Duration duration;
  final Widget? child;

  const RipplePulse({
    super.key,
    this.size = 180,
    this.color = const Color(0xFF0EA5E9),
    this.ringCount = 3,
    this.duration = const Duration(milliseconds: 2400),
    this.child,
  });

  @override
  State<RipplePulse> createState() => _RipplePulseState();
}

class _RipplePulseState extends State<RipplePulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RipplePainter(
                  progress: _controller.value,
                  color: widget.color,
                  ringCount: widget.ringCount,
                ),
              );
            },
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int ringCount;

  _RipplePainter({
    required this.progress,
    required this.color,
    required this.ringCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < ringCount; i++) {
      // Stagger each ripple ring phase
      final ringProgress = (progress + (i / ringCount)) % 1.0;
      final radius = math.max(0.0, ringProgress * maxRadius);

      // Fade out as it expands outwards
      final opacity = (1.0 - ringProgress).clamp(0.0, 1.0) * 0.45;

      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.2 * (1.0 - ringProgress * 0.5)).clamp(0.8, 2.5);

      canvas.drawCircle(center, radius, paint);

      // Add a subtle fill for the closest inner ring
      if (ringProgress < 0.45) {
        final fillPaint = Paint()
          ..color = color.withValues(alpha: (0.12 * (1.0 - ringProgress / 0.45)).clamp(0.0, 0.12))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
