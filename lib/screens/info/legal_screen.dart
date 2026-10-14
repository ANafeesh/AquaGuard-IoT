import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final bool isPrivacyPolicy;

  const LegalScreen({
    super.key,
    this.title = 'Regulatory & Legal Notice',
    this.isPrivacyPolicy = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBackground : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: isPrivacyPolicy ? _buildPrivacyContent(isDark) : _buildTermsContent(isDark),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPrivacyContent(bool isDark) {
    return [
      Text('Community Data Sharing & Governance', style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 16)),
      const SizedBox(height: 10),
      Text(
        'AquaGuard is built on open, transparent civic environmental monitoring. Sensor telemetry contributed by hardware nodes and community members is anonymized and aggregated into community ledgers.',
        style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(fontSize: 13, height: 1.5),
      ),
      const SizedBox(height: 16),
      Text('1. Information We Collect', style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 14)),
      const SizedBox(height: 4),
      Text(
        '• Geolocation coordinates attached to public water sources\n• Water quality parameter readings (pH, TDS, turbidity, temp)\n• Volunteer observation notes and optional photographic records',
        style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(fontSize: 12.5, height: 1.6),
      ),
      const SizedBox(height: 16),
      Text('2. Data Ownership & Storage', style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 14)),
      const SizedBox(height: 4),
      Text(
        'All observations remain accessible to participating watershed communities. Personal credentials are securely stored using industry-standard hashing.',
        style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(fontSize: 12.5, height: 1.5),
      ),
    ];
  }

  List<Widget> _buildTermsContent(bool isDark) {
    return [
      Text('Official Regulatory & Limitations Notice', style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 16)),
      const SizedBox(height: 10),
      Text(
        'AquaGuard monitors selected water-quality indicators (pH, TDS/EC, turbidity, and water temperature) using an ESP32 hardware node and community observations.',
        style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(fontSize: 13, height: 1.5),
      ),
      const SizedBox(height: 16),
      Text('1. Non-Potable Water Notice', style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 14)),
      const SizedBox(height: 4),
      Text(
        'AquaGuard DOES NOT certify whether water is safe to drink, potable, or free of biological pathogens. All classifications represent environmental sensor baseline comparisons only. Always consult authorized public health authorities and certified laboratory testing before consuming water from unverified sources.',
        style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(fontSize: 12.5, height: 1.5),
      ),
      const SizedBox(height: 16),
      Text('2. Community Sensor Guidelines', style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 14)),
      const SizedBox(height: 4),
      Text(
        'Participants pledge to record accurate physical readings, calibrated probe outputs, and honest qualitative descriptions of water bodies.',
        style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(fontSize: 12.5, height: 1.5),
      ),
    ];
  }
}
