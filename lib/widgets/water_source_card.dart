import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/water_source.dart';
import 'status_badge.dart';

class WaterSourceCard extends StatelessWidget {
  final WaterSource source;
  final VoidCallback onTap;
  final bool isSelected;

  const WaterSourceCard({
    super.key,
    required this.source,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryAqua
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryAqua.withValues(alpha: isDark ? 0.25 : 0.12)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Name and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(
                          fontSize: 16.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              source.coordinates,
                              style: (isDark ? AppTypography.darkSecondary : AppTypography.muted).copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: source.status),
              ],
            ),
            const SizedBox(height: 14),

            // Metrics Summary Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSubtleBg : AppColors.mainBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricItem('pH', source.ph?.toStringAsFixed(1) ?? '--', isDark),
                  _divider(isDark),
                  _metricItem('TDS', source.tdsEc != null ? '${source.tds} ppm' : '--', isDark),
                  _divider(isDark),
                  _metricItem('Turbidity', source.turbidity != null ? '${source.turbidity} NTU' : '--', isDark),
                  _divider(isDark),
                  _metricItem('Temp', source.temperature != null ? '${source.temperature}°C' : '--', isDark),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Footer: Updated time and Action Link
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      source.lastUpdated,
                      style: (isDark ? AppTypography.darkSecondary : AppTypography.muted).copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'View Details',
                      style: AppTypography.secondary.copyWith(
                        color: isDark ? AppColors.primaryAqua : AppColors.primaryDeepOcean,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: isDark ? AppColors.primaryAqua : AppColors.primaryDeepOcean,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricItem(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: (isDark ? AppTypography.darkSecondary : AppTypography.muted).copyWith(fontSize: 10.5),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: AppTypography.secondary.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      height: 22,
      width: 1,
      color: isDark ? AppColors.darkBorder : AppColors.border,
    );
  }
}
