import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Prominently displays the required regulatory and limitations notice:
/// "AquaGuard monitors selected water-quality indicators (pH, TDS/EC, turbidity, temperature).
/// It does not certify whether water is safe to drink."
class DisclaimerBanner extends StatelessWidget {
  final bool compact;
  final EdgeInsetsGeometry? margin;

  const DisclaimerBanner({
    super.key,
    this.compact = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.symmetric(
        horizontal: 13,
        vertical: compact ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132238) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFD1FAE5),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3.5,
            height: compact ? 36 : 48,
            margin: const EdgeInsets.only(right: 10, top: 2),
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 1.0),
            child: Icon(
              Icons.info_outline_rounded,
              size: 17,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact) ...[
                  Text(
                    'Indicator Monitoring Notice',
                    style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  'AquaGuard monitors selected indicators (pH, TDS/EC, turbidity, temperature) '
                  'from IoT nodes and community logs. It does not certify whether water is safe to drink.',
                  style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
                    fontSize: compact ? 11.5 : 12,
                    height: 1.35,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
