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
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? AppColors.teal.withValues(alpha: 0.3)
              : AppColors.teal.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: compact ? 18 : 20,
            color: AppColors.teal,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!compact) ...[
                  Text(
                    'Indicator Monitoring Notice',
                    style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(
                      fontSize: 13,
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
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
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
