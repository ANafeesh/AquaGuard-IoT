import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/water_source.dart';

class InteractiveMapWidget extends StatefulWidget {
  final List<WaterSource> waterSources;
  final WaterSource selectedSource;
  final ValueChanged<WaterSource> onSourceSelected;
  final String mapStyle;

  const InteractiveMapWidget({
    super.key,
    required this.waterSources,
    required this.selectedSource,
    required this.onSourceSelected,
    this.mapStyle = 'Standard',
  });

  @override
  State<InteractiveMapWidget> createState() => _InteractiveMapWidgetState();
}

class _InteractiveMapWidgetState extends State<InteractiveMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Map coordinates relative to 0..1 bounding box for simulation
  Offset _getNormalizedPos(WaterSource s) {
    switch (s.id) {
      case 'ws-1': // Lake View Point
        return const Offset(0.38, 0.42);
      case 'ws-2': // Riverside
        return const Offset(0.72, 0.32);
      case 'ws-3': // Community Well
        return const Offset(0.30, 0.68);
      case 'ws-4': // North Reservoir
        return const Offset(0.60, 0.18);
      case 'ws-5': // Village Water Point
        return const Offset(0.20, 0.82);
      default:
        return const Offset(0.5, 0.5);
    }
  }

  Color _getStatusColor(WaterQualityStatus status) {
    switch (status) {
      case WaterQualityStatus.withinTypicalRange:
        return AppColors.statusNormal;
      case WaterQualityStatus.unusual:
        return AppColors.statusWarning;
      case WaterQualityStatus.noRecentData:
        return AppColors.secondaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: [
            // Custom Map Canvas Background (Simulated satellite / vector water map)
            CustomPaint(
              size: Size(width, height),
              painter: _MapCanvasPainter(mapStyle: widget.mapStyle),
            ),

            // Top Water bodies / Zone Labels
            Positioned(
              top: 24,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryAqua,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Simulated Catchment Zone A',
                      style: AppTypography.muted.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDeepOcean,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Interactive Markers
            ...widget.waterSources.map((source) {
              final pos = _getNormalizedPos(source);
              final isSelected = widget.selectedSource.id == source.id;
              final markerColor = _getStatusColor(source.status);

              return Positioned(
                left: pos.dx * width - 24,
                top: pos.dy * height - 48,
                child: GestureDetector(
                  onTap: () => widget.onSourceSelected(source),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Label badge when selected or hovered
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: isSelected ? 1.0 : 0.85,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryDeepOcean
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryAqua
                                  : AppColors.border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            source.name,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.primaryText,
                            ),
                          ),
                        ),
                      ),

                      // Pulse ring + Pin
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isSelected)
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Container(
                                  width: 44 + (_pulseController.value * 16),
                                  height: 44 + (_pulseController.value * 16),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: markerColor.withValues(
                                      alpha: 0.35 * (1 - _pulseController.value),
                                    ),
                                  ),
                                );
                              },
                            ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: markerColor,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: markerColor.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.water_drop_rounded,
                              size: 18,
                              color: markerColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final String mapStyle;

  _MapCanvasPainter({this.mapStyle = 'Standard'});

  @override
  void paint(Canvas canvas, Size size) {
    final bool isSatellite = mapStyle == 'Satellite';
    final bool isTerrain = mapStyle == 'Terrain';

    // Background terrain
    final bgPaint = Paint()
      ..color = isSatellite
          ? const Color(0xFF1E293B) // Dark satellite slate
          : (isTerrain ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Green vegetative park patches
    final parkPaint = Paint()
      ..color = isSatellite
          ? const Color(0xFF14532D) // Dark forest
          : (isTerrain ? const Color(0xFFD9F99D) : const Color(0xFFE2EFE9))
      ..style = PaintingStyle.fill;

    final parkPath1 = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 20, size.width * 0.45, size.height * 0.35),
        const Radius.circular(30),
      ));
    canvas.drawPath(parkPath1, parkPaint);

    final parkPath2 = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.5, size.height * 0.5, size.width * 0.45,
            size.height * 0.4),
        const Radius.circular(40),
      ));
    canvas.drawPath(parkPath2, parkPaint);

    // Simulated Lake body (Aqua)
    final lakePaint = Paint()
      ..color = isSatellite
          ? const Color(0xFF0369A1) // Deep ocean blue
          : (isTerrain ? const Color(0xFF0D9488) : const Color(0xFFBAE6FD))
      ..style = PaintingStyle.fill;

    final lakeBorderPaint = Paint()
      ..color = isSatellite
          ? const Color(0xFF38BDF8)
          : (isTerrain ? const Color(0xFF14B8A6) : const Color(0xFF38BDF8))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final lakePath = Path()
      ..moveTo(size.width * 0.22, size.height * 0.35)
      ..cubicTo(size.width * 0.30, size.height * 0.28, size.width * 0.48,
          size.height * 0.30, size.width * 0.52, size.height * 0.42)
      ..cubicTo(size.width * 0.55, size.height * 0.52, size.width * 0.42,
          size.height * 0.58, size.width * 0.32, size.height * 0.54)
      ..cubicTo(size.width * 0.22, size.height * 0.50, size.width * 0.16,
          size.height * 0.42, size.width * 0.22, size.height * 0.35);

    canvas.drawPath(lakePath, lakePaint);
    canvas.drawPath(lakePath, lakeBorderPaint);

    // Simulated River Stream
    final riverPaint = Paint()
      ..color = const Color(0xFF7DD3FC)
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final riverPath = Path()
      ..moveTo(size.width * 0.50, size.height * 0.05)
      ..cubicTo(size.width * 0.65, size.height * 0.22, size.width * 0.70,
          size.height * 0.38, size.width * 0.78, size.height * 0.60)
      ..cubicTo(size.width * 0.82, size.height * 0.75, size.width * 0.88,
          size.height * 0.88, size.width * 0.95, size.height * 0.98);

    canvas.drawPath(riverPath, riverPaint);

    // Secondary Canal
    final canalPaint = Paint()
      ..color = const Color(0xFFBAE6FD)
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final canalPath = Path()
      ..moveTo(size.width * 0.38, size.height * 0.52)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.70,
          size.width * 0.22, size.height * 0.82);

    canvas.drawPath(canalPath, canalPaint);

    // Simulated Road Network
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 6.5
      ..style = PaintingStyle.stroke;

    final road1 = Path()
      ..moveTo(0, size.height * 0.48)
      ..lineTo(size.width, size.height * 0.48);

    final road2 = Path()
      ..moveTo(size.width * 0.45, 0)
      ..lineTo(size.width * 0.45, size.height);

    final road3 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.2)
      ..lineTo(size.width * 0.9, size.height * 0.8);

    for (final p in [road1, road2, road3]) {
      canvas.drawPath(p, roadBorderPaint);
      canvas.drawPath(p, roadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
