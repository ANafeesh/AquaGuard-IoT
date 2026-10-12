import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/config/parameter_thresholds.dart';
import '../core/widgets/disclaimer_banner.dart';
import '../models/water_source.dart';
import '../widgets/status_badge.dart';
import 'history_screen.dart';
import 'report_measurement_screen.dart';

class WaterSourceDetailsScreen extends ConsumerWidget {
  final WaterSource waterSource;

  const WaterSourceDetailsScreen({
    super.key,
    required this.waterSource,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: Text(
          waterSource.name,
          style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Share source info',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Source telemetry link copied.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Regulatory Notice Banner
              const DisclaimerBanner(),
              const SizedBox(height: 14),

              // Header Overview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBackground : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StatusBadge(status: waterSource.status),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              waterSource.lastUpdated,
                              style: AppTypography.muted.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      waterSource.name,
                      style: (isDark ? AppTypography.darkLargeTitle : AppTypography.largeTitle).copyWith(
                        fontSize: 22,
                        color: AppColors.primaryDeepOcean,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.primaryAqua,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${waterSource.type.displayName} • ${waterSource.coordinates}',
                          style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    if (waterSource.description != null && waterSource.description!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        waterSource.description!,
                        style: (isDark ? AppTypography.darkBody : AppTypography.body).copyWith(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Current Measurements Header
              Text(
                'Current Indicator Measurements',
                style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading),
              ),
              const SizedBox(height: 12),

              // 4 Detailed Metric Cards with status indicators
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      icon: Icons.water_drop_rounded,
                      name: ParameterThresholds.phLabel,
                      value: waterSource.ph?.toStringAsFixed(2) ?? '--',
                      unit: 'Unitless',
                      normalRange: '${ParameterThresholds.phMin} - ${ParameterThresholds.phMax}',
                      status: waterSource.status,
                      color: AppColors.primaryAqua,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      icon: Icons.waves_rounded,
                      name: ParameterThresholds.tdsLabel,
                      value: '${waterSource.tds}',
                      unit: ParameterThresholds.tdsUnit,
                      normalRange: '${ParameterThresholds.tdsMin.toInt()} - ${ParameterThresholds.tdsMax.toInt()} ${ParameterThresholds.tdsUnit}',
                      status: waterSource.status,
                      color: AppColors.teal,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      icon: Icons.remove_red_eye_outlined,
                      name: ParameterThresholds.turbidityLabel,
                      value: waterSource.turbidity?.toStringAsFixed(1) ?? '--',
                      unit: ParameterThresholds.turbidityUnit,
                      normalRange: '${ParameterThresholds.turbidityMin} - ${ParameterThresholds.turbidityMax} ${ParameterThresholds.turbidityUnit}',
                      status: waterSource.status,
                      color: const Color(0xFF0284C7),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      icon: Icons.thermostat_rounded,
                      name: ParameterThresholds.tempLabel,
                      value: waterSource.temperature?.toStringAsFixed(1) ?? '--',
                      unit: ParameterThresholds.tempUnit,
                      normalRange: '${ParameterThresholds.tempMin.toInt()} - ${ParameterThresholds.tempMax.toInt()} ${ParameterThresholds.tempUnit}',
                      status: waterSource.status,
                      color: const Color(0xFFEA580C),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.show_chart_rounded, size: 18),
                      label: const Text('View History', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryDeepOcean,
                        side: const BorderSide(color: AppColors.primaryAqua, width: 1.3),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryScreen(initialSource: waterSource),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                      label: const Text('Add Reading', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDeepOcean,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportMeasurementScreen(preselectedSourceId: waterSource.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String name,
    required String value,
    required String unit,
    required String normalRange,
    required WaterQualityStatus status,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: status == WaterQualityStatus.unusual
                      ? AppColors.statusWarning
                      : AppColors.teal,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: AppTypography.muted.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: (isDark ? AppTypography.darkMeasurementValue : AppTypography.measurementValue).copyWith(
                  fontSize: 22,
                ),
              ),
              if (unit.isNotEmpty && unit != 'Unitless') ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: AppTypography.muted.copyWith(fontSize: 10),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Baseline: $normalRange',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
