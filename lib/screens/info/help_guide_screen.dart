import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../constants/parameter_thresholds.dart';

class HelpGuideScreen extends StatelessWidget {
  const HelpGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Indicator Guide & Help'),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Understanding Water Quality Indicators',
                style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading).copyWith(fontSize: 17),
              ),
              const SizedBox(height: 6),
              Text(
                'AquaGuard monitors ambient aquatic health using standardized environmental telemetry indicators.',
                style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(fontSize: 13),
              ),
              const SizedBox(height: 20),

              _indicatorCard(
                title: ParameterThresholds.phLabel,
                range: '${ParameterThresholds.phMin} – ${ParameterThresholds.phMax}',
                description:
                    'Indicates acidity or basicity. Typical natural freshwater systems fall within 6.5 to 8.5. Values outside this band may point to chemical runoff or unusual biological activity.',
                icon: Icons.water_drop_rounded,
                color: AppColors.primaryAqua,
                isDark: isDark,
              ),
              _indicatorCard(
                title: ParameterThresholds.tdsLabel,
                range: '${ParameterThresholds.tdsMin.toInt()} – ${ParameterThresholds.tdsMax.toInt()} ${ParameterThresholds.tdsUnit}',
                description:
                    'Total Dissolved Solids reflects dissolved mineral content and inorganic salts. Typical freshwater rivers operate between 150 and 500 ppm.',
                icon: Icons.waves_rounded,
                color: AppColors.teal,
                isDark: isDark,
              ),
              _indicatorCard(
                title: ParameterThresholds.turbidityLabel,
                range: '${ParameterThresholds.turbidityMin} – ${ParameterThresholds.turbidityMax} ${ParameterThresholds.turbidityUnit}',
                description:
                    'Measures water clarity and suspended particulate matter. Clear ambient water is below 5.0 NTU. Spikes occur during heavy rain or sediment disturbance.',
                icon: Icons.remove_red_eye_outlined,
                color: const Color(0xFF0284C7),
                isDark: isDark,
              ),
              _indicatorCard(
                title: ParameterThresholds.tempLabel,
                range: '${ParameterThresholds.tempMin.toInt()} – ${ParameterThresholds.tempMax.toInt()} ${ParameterThresholds.tempUnit}',
                description:
                    'Ambient water temperature affects oxygen saturation and aquatic metabolism. Typical regional ambient water registers between 20°C and 32°C.',
                icon: Icons.thermostat_rounded,
                color: const Color(0xFFEA580C),
                isDark: isDark,
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF132238) : AppColors.altLightAquaBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Important Reminder: AquaGuard is designed for environmental monitoring and community mapping. It does not certify drinking water safety.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.teal.shade200 : AppColors.teal,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _indicatorCard({
    required String title,
    required String range,
    required String description,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 15),
                    ),
                    Text(
                      'Typical Baseline: $range',
                      style: const TextStyle(color: AppColors.primaryAqua, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
              fontSize: 13,
              color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
