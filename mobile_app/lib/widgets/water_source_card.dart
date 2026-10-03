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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primaryAqua : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryAqua.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.02),
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
                        style: AppTypography.cardTitle.copyWith(
                          fontSize: 16.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: AppColors.mutedText,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              source.coordinates,
                              style: AppTypography.muted.copyWith(fontSize: 11),
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
                color: AppColors.mainBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _metricItem('pH', source.ph.toStringAsFixed(1)),
                  _divider(),
                  _metricItem('TDS', '${source.tds} ppm'),
                  _divider(),
                  _metricItem('Turbidity', '${source.turbidity} NTU'),
                  _divider(),
                  _metricItem('Temp', '${source.temperature}°C'),
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
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      source.lastUpdated,
                      style: AppTypography.muted.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'View Details',
                      style: AppTypography.secondary.copyWith(
                        color: AppColors.primaryDeepOcean,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.primaryDeepOcean,
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

  Widget _metricItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.muted.copyWith(fontSize: 10.5),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: AppTypography.secondary.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.primaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 22,
      width: 1,
      color: AppColors.border,
    );
  }
}
