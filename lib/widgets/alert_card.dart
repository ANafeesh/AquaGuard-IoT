import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/alert_item.dart';
import '../models/water_source.dart';

class AlertCard extends StatelessWidget {
  final AlertItem alert;
  final VoidCallback? onViewDetails;

  const AlertCard({
    super.key,
    required this.alert,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color iconColor;
    Color bgColor;

    switch (alert.severity) {
      case WaterQualityStatus.unusual:
        borderColor = AppColors.statusWarning.withValues(alpha: 0.4);
        iconColor = AppColors.statusWarning;
        bgColor = AppColors.statusWarningBg.withValues(alpha: 0.4);
        break;
      case WaterQualityStatus.noRecentData:
        borderColor = AppColors.secondaryText.withValues(alpha: 0.35);
        iconColor = AppColors.secondaryText;
        bgColor = AppColors.mainBackground;
        break;
      case WaterQualityStatus.withinTypicalRange:
        borderColor = AppColors.border;
        iconColor = AppColors.primaryAqua;
        bgColor = AppColors.cardBackground;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 15.5,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.timeAgo,
                      style: AppTypography.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.description,
            style: AppTypography.body.copyWith(
              fontSize: 13.5,
              color: AppColors.primaryText.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          // Technical clarification note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alert.investigationAdvice,
                    style: AppTypography.muted.copyWith(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onViewDetails,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryDeepOcean,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppColors.border),
                ),
                backgroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(
                'View Details',
                style: AppTypography.button.copyWith(
                  fontSize: 13,
                  color: AppColors.primaryDeepOcean,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
