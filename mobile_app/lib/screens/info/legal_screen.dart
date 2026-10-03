import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final bool isPrivacyPolicy;

  const LegalScreen({
    super.key,
    required this.title,
    this.isPrivacyPolicy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: isPrivacyPolicy ? _buildPrivacyContent() : _buildTermsContent(),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPrivacyContent() {
    return [
      Text('Community Data Sharing & Governance', style: AppTypography.cardTitle.copyWith(fontSize: 16)),
      const SizedBox(height: 10),
      Text(
        'AquaGuard is built on open, transparent civic environmental monitoring. Sensor telemetry contributed by hardware nodes and community members is anonymized and aggregated into community ledgers.',
        style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.secondaryText, height: 1.5),
      ),
      const SizedBox(height: 16),
      Text('1. Information We Collect', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
      const SizedBox(height: 4),
      Text(
        '• Geolocation coordinates attached to public water sources\n• Water quality parameter readings (pH, TDS, turbidity, temp)\n• Volunteer observation notes and optional photographic records',
        style: AppTypography.body.copyWith(fontSize: 12.5, color: AppColors.secondaryText, height: 1.6),
      ),
      const SizedBox(height: 16),
      Text('2. Data Ownership & Storage', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
      const SizedBox(height: 4),
      Text(
        'All observations remain accessible to participating watershed communities. Personal credentials are securely stored using industry-standard hashing.',
        style: AppTypography.body.copyWith(fontSize: 12.5, color: AppColors.secondaryText, height: 1.5),
      ),
    ];
  }

  List<Widget> _buildTermsContent() {
    return [
      Text('Terms of Community Observation', style: AppTypography.cardTitle.copyWith(fontSize: 16)),
      const SizedBox(height: 10),
      Text(
        'By submitting observations or operating monitoring nodes, you contribute to a communal environmental database. Please review the following operating guidelines.',
        style: AppTypography.body.copyWith(fontSize: 13, color: AppColors.secondaryText, height: 1.5),
      ),
      const SizedBox(height: 16),
      Text('1. Non-Potable Advisory', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
      const SizedBox(height: 4),
      Text(
        'Data provided by AquaGuard is for environmental and ambient water quality awareness. It must not be cited as certification of potable water safety or used in place of accredited municipal laboratory assays.',
        style: AppTypography.body.copyWith(fontSize: 12.5, color: AppColors.secondaryText, height: 1.5),
      ),
      const SizedBox(height: 16),
      Text('2. Volunteer Integrity', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
      const SizedBox(height: 4),
      Text(
        'Participants pledge to record accurate physical readings, calibrated probe outputs, and honest qualitative descriptions of water bodies.',
        style: AppTypography.body.copyWith(fontSize: 12.5, color: AppColors.secondaryText, height: 1.5),
      ),
    ];
  }
}
