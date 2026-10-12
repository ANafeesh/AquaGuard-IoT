import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/config/app_config.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('About AquaGuard'),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 14),
              Text(
                'AquaGuard',
                style: (isDark ? AppTypography.darkLargeTitle : AppTypography.largeTitle).copyWith(
                  fontSize: 24,
                  color: AppColors.primaryDeepOcean,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Version ${AppConfig.appVersion} (Build ${AppConfig.appBuild})',
                style: AppTypography.muted,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBackground : AppColors.altLightAquaBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'IoT Environmental Monitoring & Community Mapping',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Mandatory Limitations Statement Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFFD97706),
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Official Limitations Statement',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppConfig.limitationsStatement,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Project Description Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBackground : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project Description',
                      style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AquaGuard monitors selected water-quality indicators (pH, TDS/EC, turbidity, temperature) '
                      'from an ESP32 hardware node equipped with GPS, and combines this telemetry with decentralized '
                      'community mapping and observations. All metrics are benchmarked against historical baseline '
                      'indicators to detect environmental changes early.',
                      style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Monitored Indicators',
                      style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• pH Level: Acidity/alkalinity indicator (Unitless)\n'
                      '• TDS / EC: Total Dissolved Solids / Electrical Conductivity (ppm or µS/cm)\n'
                      '• Turbidity: Cloudiness/suspended particulate matter (NTU)\n'
                      '• Temperature: Thermal baseline fluctuations (°C or °F)',
                      style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
                        fontSize: 12.5,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hardware & Cloud Stack',
                      style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Edge Node: ESP32 SoC with GPS and multi-probe sensor array\n'
                      '• Backend: Cloud Firestore & Firebase Authentication\n'
                      '• Mobile Client: Flutter (Dart) with Riverpod, fl_chart, and OpenStreetMap\n'
                      '• Edge Anomaly Detection: 3-standard-deviation rolling z-score & delta checks',
                      style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
                        fontSize: 12.5,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
