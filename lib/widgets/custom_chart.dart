import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/measurement.dart';

class CustomChartCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Map<String, List<HistoricalPoint>> dataByRange;
  final String unit;
  final double? normalMin;
  final double? normalMax;

  const CustomChartCard({
    super.key,
    this.title = 'pH Trend',
    this.subtitle = 'Stable over the selected period (Mock Data)',
    required this.dataByRange,
    this.unit = '',
    this.normalMin,
    this.normalMax,
  });

  @override
  State<CustomChartCard> createState() => _CustomChartCardState();
}

class _CustomChartCardState extends State<CustomChartCard>
    with SingleTickerProviderStateMixin {
  String _selectedRange = '24H';
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onRangeChanged(String range) {
    if (_selectedRange == range) return;
    setState(() {
      _selectedRange = range;
    });
    _animController.reset();
    _animController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.dataByRange[_selectedRange] ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Range Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Indicator baseline comparison',
                    style: AppTypography.muted,
                  ),
                ],
              ),
              // Filter buttons: 24H | 7D | 30D
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.mainBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Row(
                  children: ['24H', '7D', '30D'].map((range) {
                    final isSelected = _selectedRange == range;
                    return GestureDetector(
                      onTap: () => _onRangeChanged(range),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryDeepOcean
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          range,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.secondaryText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Animated Canvas Chart
          SizedBox(
            height: 150,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LineChartPainter(
                    points: points,
                    progress: _animation.value,
                    unit: widget.unit,
                    lineColor: AppColors.primaryAqua,
                    gradientStartColor:
                        AppColors.primaryAqua.withValues(alpha: 0.28),
                    gradientEndColor:
                        AppColors.primaryAqua.withValues(alpha: 0.0),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // X-Axis Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: points.map((p) {
              return Text(
                p.timeLabel,
                style: AppTypography.muted.copyWith(fontSize: 11),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Bottom status text with clean icon
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.altLightAquaBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.25), width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 15,
                  color: AppColors.teal,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    widget.subtitle,
                    style: AppTypography.secondary.copyWith(
                      color: AppColors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<HistoricalPoint> points;
  final double progress;
  final String unit;
  final Color lineColor;
  final Color gradientStartColor;
  final Color gradientEndColor;

  _LineChartPainter({
    required this.points,
    required this.progress,
    required this.unit,
    required this.lineColor,
    required this.gradientStartColor,
    required this.gradientEndColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double minVal =
        points.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final double maxVal =
        points.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);
    final double paddingY = 16.0;
    final double chartHeight = size.height - (paddingY * 2);

    // Draw horizontal dashed grid lines
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = paddingY + (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final double stepX = size.width / (points.length - 1);

    final linePath = Path();
    final fillPath = Path();

    final List<Offset> computedOffsets = [];

    for (int i = 0; i < points.length; i++) {
      final normalizedY = (points[i].value - minVal) / range;
      // Invert Y coordinate
      final y = size.height - paddingY - (normalizedY * chartHeight);
      final x = i * stepX;
      computedOffsets.add(Offset(x, y));
    }

    // Build smooth cubic bezier curve
    linePath.moveTo(computedOffsets[0].dx, computedOffsets[0].dy);
    fillPath.moveTo(computedOffsets[0].dx, size.height);
    fillPath.lineTo(computedOffsets[0].dx, computedOffsets[0].dy);

    for (int i = 0; i < computedOffsets.length - 1; i++) {
      final p0 = computedOffsets[i];
      final p1 = computedOffsets[i + 1];

      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      linePath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );

      fillPath.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p1.dx,
        p1.dy,
      );
    }

    fillPath.lineTo(computedOffsets.last.dx, size.height);
    fillPath.close();

    // Clip with progress animation
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    // Gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [gradientStartColor, gradientEndColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Draw point markers
    for (int i = 0; i < computedOffsets.length; i++) {
      final offset = computedOffsets[i];
      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final dotStroke = Paint()
        ..color = lineColor
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(offset, 4.5, dotPaint);
      canvas.drawCircle(offset, 4.5, dotStroke);

      // Highlight latest point
      if (i == computedOffsets.length - 1) {
        final haloPaint = Paint()
          ..color = lineColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(offset, 8.5, haloPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.points != points;
  }
}
