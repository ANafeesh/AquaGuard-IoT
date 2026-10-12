import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../models/measurement.dart';

/// Production-ready Line Chart powered by fl_chart with interactive touch tooltips,
/// gradient fill, and "No data for this range" empty state.
class FlParameterChart extends StatelessWidget {
  final String title;
  final String parameterName;
  final String unit;
  final List<HistoricalPoint> points;
  final String selectedRange; // '24h', '7d', '30d', 'All'
  final ValueChanged<String> onRangeChanged;
  final Color primaryColor;
  final Color accentColor;

  const FlParameterChart({
    super.key,
    required this.title,
    required this.parameterName,
    required this.unit,
    required this.points,
    required this.selectedRange,
    required this.onRangeChanged,
    this.primaryColor = AppColors.primaryAqua,
    this.accentColor = AppColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCardBackground : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Range Selector (24h, 7d, 30d, All)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap any data point to inspect value and timestamp',
                      style: AppTypography.muted.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Range Filter Pill Buttons
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardSubtleBg : AppColors.mainBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Row(
                  children: ['24h', '7d', '30d', 'All'].map((range) {
                    final isSelected = selectedRange.toLowerCase() == range.toLowerCase();
                    return GestureDetector(
                      onTap: () => onRangeChanged(range),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
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

          // Chart or Empty State
          if (points.isEmpty)
            _buildEmptyRangeState(isDark)
          else
            SizedBox(
              height: 200,
              width: double.infinity,
              child: _buildLineChart(isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyRangeState(bool isDark) {
    return Container(
      height: 180,
      width: double.infinity,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.query_builder_rounded,
              size: 38,
              color: AppColors.mutedText.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 10),
            Text(
              'No data for this range',
              style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try selecting 7d, 30d, or All to view previous historical telemetry.',
              style: AppTypography.muted.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
    );
  }

  Widget _buildLineChart(bool isDark) {
    final spots = <FlSpot>[];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].value));
    }

    final double minY = points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final double maxY = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final double marginY = (maxY - minY == 0) ? 1.0 : (maxY - minY) * 0.15;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: (minY - marginY).clamp(0.0, double.infinity),
        maxY: maxY + marginY,
        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 10,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final idx = barSpot.x.toInt();
                final pt = (idx >= 0 && idx < points.length) ? points[idx] : null;
                final time = pt?.timeLabel ?? '';
                final val = barSpot.y.toStringAsFixed(2);
                return LineTooltipItem(
                  '$val $unit\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text: time,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 3).clamp(0.1, 100.0),
          getDrawingHorizontalLine: (value) => FlLine(
            color: (isDark ? AppColors.darkBorder : AppColors.border).withValues(alpha: 0.6),
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    value.toStringAsFixed(value >= 100 ? 0 : 1),
                    style: AppTypography.muted.copyWith(fontSize: 10),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: points.length > 5 ? (points.length / 4).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < points.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      points[idx].timeLabel,
                      style: AppTypography.muted.copyWith(fontSize: 10),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: primaryColor,
            barWidth: 2.8,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: Colors.white,
                  strokeWidth: 2.2,
                  strokeColor: primaryColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  primaryColor.withValues(alpha: 0.28),
                  primaryColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
