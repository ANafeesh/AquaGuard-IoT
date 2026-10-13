import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../animations/pulse_indicator.dart';
import '../../models/water_source.dart';

class StatusBadge extends StatelessWidget {
  final WaterQualityStatus status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    Color dotColor;
    String text;
    bool isPulsing = true;
    Duration pulseDuration = const Duration(milliseconds: 2200);

    switch (status) {
      case WaterQualityStatus.withinTypicalRange:
        bg = isDark ? AppColors.statusNormalDarkBg : AppColors.statusNormalBg;
        fg = isDark ? Colors.teal.shade200 : AppColors.statusNormal;
        dotColor = fg;
        text = isCompact ? 'Normal' : 'Within expected range';
        isPulsing = true;
        pulseDuration = const Duration(milliseconds: 2400);
        break;
      case WaterQualityStatus.unusual:
        bg = isDark ? AppColors.statusWarningDarkBg : AppColors.statusWarningBg;
        fg = isDark ? Colors.amber.shade300 : AppColors.statusWarning;
        dotColor = fg;
        text = isCompact ? 'Unusual' : 'Unusual change detected';
        isPulsing = true;
        pulseDuration = const Duration(milliseconds: 1300);
        break;
      case WaterQualityStatus.noRecentData:
        bg = isDark ? AppColors.statusNeutralDarkBg : AppColors.statusNeutralBg;
        fg = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
        dotColor = isDark ? Colors.grey.shade400 : AppColors.mutedText;
        text = isCompact ? 'No data' : 'No recent data';
        isPulsing = false;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseIndicator(
            color: dotColor,
            size: isCompact ? 5.5 : 6.5,
            haloScale: 2.2,
            duration: pulseDuration,
            isActive: isPulsing,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTypography.statusBadge.copyWith(
              color: fg,
              fontSize: isCompact ? 10.5 : 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
