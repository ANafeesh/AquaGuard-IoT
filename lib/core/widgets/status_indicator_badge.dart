import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
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

    switch (status) {
      case WaterQualityStatus.withinTypicalRange:
        bg = isDark ? AppColors.statusNormalDarkBg : AppColors.statusNormalBg;
        fg = isDark ? Colors.teal.shade200 : AppColors.statusNormal;
        dotColor = fg;
        text = isCompact ? 'Normal' : 'Within expected range';
        break;
      case WaterQualityStatus.unusual:
        bg = isDark ? AppColors.statusWarningDarkBg : AppColors.statusWarningBg;
        fg = isDark ? Colors.amber.shade300 : AppColors.statusWarning;
        dotColor = fg;
        text = isCompact ? 'Unusual' : 'Unusual change detected';
        break;
      case WaterQualityStatus.noRecentData:
        bg = isDark ? AppColors.statusNeutralDarkBg : AppColors.statusNeutralBg;
        fg = isDark ? AppColors.darkSecondaryText : AppColors.secondaryText;
        dotColor = isDark ? Colors.grey.shade400 : AppColors.mutedText;
        text = isCompact ? 'No data' : 'No recent data';
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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
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
