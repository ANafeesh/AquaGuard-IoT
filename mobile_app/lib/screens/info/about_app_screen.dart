import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../config/app_config.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('About AquaGuard'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
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
              Text('AquaGuard', style: AppTypography.largeTitle.copyWith(fontSize: 24, color: AppColors.primaryDeepOcean)),
              const SizedBox(height: 2),
              Text('Version ${AppConfig.appVersion}', style: AppTypography.muted),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.altLightAquaBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'IoT Environmental Monitoring & Community Mapping',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.teal),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System Mission', style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(
                      'AquaGuard empowers communities and watershed managers to track ambient freshwater quality indicators through connected IoT sensor nodes, visual telemetry analytics, and crowdsourced field observations.',
                      style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.secondaryText),
                    ),
                    const SizedBox(height: 16),
                    Text('Architecture Highlights', style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(
                      '• ESP32 multi-sensor telemetry (pH, TDS/EC, Turbidity, Temp)\n• Low-latency Cloud Firestore integration with offline cache\n• Rolling window anomaly detection algorithm (|z-score| > 3)\n• Open community mapping & decentralized observations',
                      style: AppTypography.body.copyWith(fontSize: 12.5, color: AppColors.secondaryText, height: 1.6),
                    ),
                    const SizedBox(height: 16),
                    Text('Compliance & Disclaimers', style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                    const SizedBox(height: 8),
                    Text(
                      'AquaGuard measurements reflect ambient water quality indicators for environmental monitoring. They do not independently certify potable drinking water safety.',
                      style: AppTypography.body.copyWith(fontSize: 12, color: AppColors.mutedText, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
