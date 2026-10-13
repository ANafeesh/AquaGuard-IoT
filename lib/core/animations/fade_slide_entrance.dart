import 'package:flutter/material.dart';

enum SlideDirection {
  up,
  down,
  left,
  right,
  none,
}

/// A smooth entrance animation that fades and slides widgets into view.
/// Supports staggered sequence delays using interval-based curves with zero pending timers.
class FadeSlideEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;
  final Duration staggerDelay;
  final Duration duration;
  final SlideDirection direction;
  final double offsetDistance;
  final Curve curve;

  const FadeSlideEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = Duration.zero,
    this.staggerDelay = const Duration(milliseconds: 40),
    this.duration = const Duration(milliseconds: 450),
    this.direction = SlideDirection.up,
    this.offsetDistance = 20.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideEntrance> createState() => _FadeSlideEntranceState();
}

class _FadeSlideEntranceState extends State<FadeSlideEntrance>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    final delayMs = widget.baseDelay.inMilliseconds +
        (widget.staggerDelay.inMilliseconds * widget.index);
    final durationMs = widget.duration.inMilliseconds;
    final totalMs = delayMs + durationMs;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs > 0 ? totalMs : durationMs),
    );

    final startFraction =
        totalMs > 0 ? (delayMs / totalMs).clamp(0.0, 0.95) : 0.0;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(startFraction, 1.0, curve: widget.curve),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

    Offset startOffset;
    switch (widget.direction) {
      case SlideDirection.up:
        startOffset = Offset(0, widget.offsetDistance);
        break;
      case SlideDirection.down:
        startOffset = Offset(0, -widget.offsetDistance);
        break;
      case SlideDirection.left:
        startOffset = Offset(widget.offsetDistance, 0);
        break;
      case SlideDirection.right:
        startOffset = Offset(-widget.offsetDistance, 0);
        break;
      case SlideDirection.none:
        startOffset = Offset.zero;
        break;
    }

    _slideAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(curved);

    _controller.forward();
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
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
