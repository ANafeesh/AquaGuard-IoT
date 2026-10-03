import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/parameter_thresholds.dart';
import '../data/mock_data.dart';
import '../models/water_source.dart';
import '../widgets/status_badge.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_chart.dart';
import 'history_screen.dart';
import 'report_measurement_screen.dart';

class WaterSourceDetailsScreen extends StatelessWidget {
  final WaterSource waterSource;

  const WaterSourceDetailsScreen({
    super.key,
    required this.waterSource,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: Text(
          waterSource.name,
          style: AppTypography.cardTitle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulated: Share source profile URL'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Saved to your monitored water sources.'),
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
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
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
                              Icons.sync_rounded,
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
                      style: AppTypography.largeTitle.copyWith(
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
                          waterSource.coordinates,
                          style: AppTypography.secondary.copyWith(
                            color: AppColors.secondaryText,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      waterSource.description,
                      style: AppTypography.body.copyWith(
                        fontSize: 13.5,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Current Measurements Header
              Text(
                'Current Sensor Readings',
                style: AppTypography.sectionHeading,
              ),
              const SizedBox(height: 12),

              // 4 Detailed Metric Cards
              Row(
                children: [
                  Expanded(
                    child: _metricCard(
                      icon: Icons.water_drop_rounded,
                      name: ParameterThresholds.phLabel,
                      value: waterSource.ph.toStringAsFixed(1),
                      unit: ParameterThresholds.phUnit,
                      normalRange: '${ParameterThresholds.phMin} - ${ParameterThresholds.phMax}',
                      status: waterSource.status,
                      color: AppColors.primaryAqua,
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
                      value: waterSource.turbidity.toStringAsFixed(1),
                      unit: ParameterThresholds.turbidityUnit,
                      normalRange: '${ParameterThresholds.turbidityMin} - ${ParameterThresholds.turbidityMax} ${ParameterThresholds.turbidityUnit}',
                      status: waterSource.status,
                      color: const Color(0xFF0284C7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _metricCard(
                      icon: Icons.thermostat_rounded,
                      name: ParameterThresholds.tempLabel,
                      value: waterSource.temperature.toStringAsFixed(1),
                      unit: ParameterThresholds.tempUnit,
                      normalRange: '${ParameterThresholds.tempMin.toInt()} - ${ParameterThresholds.tempMax.toInt()} ${ParameterThresholds.tempUnit}',
                      status: waterSource.status,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Measurement History Section
              Text(
                'Measurement History',
                style: AppTypography.sectionHeading,
              ),
              const SizedBox(height: 12),

              CustomChartCard(
                title: 'pH Baseline History',
                subtitle: 'Continuous trend over selected interval',
                dataByRange: MockData.phTrends,
                unit: '',
                normalMin: ParameterThresholds.phMin,
                normalMax: ParameterThresholds.phMax,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      text: 'View History',
                      icon: Icons.show_chart_rounded,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryScreen(
                              initialSource: waterSource,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Report Observation',
                      icon: Icons.edit_note_rounded,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportMeasurementScreen(
                              initialSourceName: waterSource.name,
                            ),
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
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              Text(
                status.shortLabel,
                style: AppTypography.muted.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: status == WaterQualityStatus.withinTypicalRange
                      ? AppColors.statusNormal
                      : (status == WaterQualityStatus.unusual
                          ? AppColors.statusWarning
                          : AppColors.secondaryText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: AppTypography.muted.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.measurementValue.copyWith(fontSize: 22),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: AppTypography.muted.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ref: $normalRange',
            style: AppTypography.muted.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
