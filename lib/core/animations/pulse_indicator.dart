import 'package:flutter/material.dart';

/// A breathing pulse indicator that renders a live pulsing halo around a dot or icon.
/// Ideal for real-time IoT sensors, status badges, and attention alerts.
class PulseIndicator extends StatefulWidget {
  final Color color;
  final double size;
  final double haloScale;
  final Duration duration;
  final bool isActive;

  const PulseIndicator({
    super.key,
    required this.color,
    this.size = 8.0,
    this.haloScale = 2.4,
    this.duration = const Duration(milliseconds: 1800),
    this.isActive = true,
  });

  @override
  State<PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.haloScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant PulseIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * widget.haloScale,
      height: widget.size * widget.haloScale,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer Pulsing Halo
            if (widget.isActive)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color.withValues(
                          alpha: _opacityAnimation.value,
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Inner Core Dot
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.45),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
