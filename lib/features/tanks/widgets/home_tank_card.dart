import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../models/home_tank.dart';
import '../../../models/water_source.dart';
import '../../../core/animations/animations.dart';
import '../screens/private_tank_dashboard_screen.dart';

class HomeTankCard extends StatelessWidget {
  final HomeTank tank;
  final VoidCallback? onRefresh;

  const HomeTankCard({
    super.key,
    required this.tank,
    this.onRefresh,
  });

  IconData _getTankIcon(HomeTankType type) {
    switch (type) {
      case HomeTankType.rooftop:
        return Icons.roofing_rounded;
      case HomeTankType.underground:
        return Icons.layers_rounded;
      case HomeTankType.rainwater:
        return Icons.water_drop_rounded;
      case HomeTankType.indoor:
        return Icons.home_work_rounded;
      case HomeTankType.other:
        return Icons.inventory_2_rounded;
    }
  }

  Color _getStatusColor(WaterQualityStatus status) {
    switch (status) {
      case WaterQualityStatus.withinTypicalRange:
        return AppColors.teal;
      case WaterQualityStatus.unusual:
        return AppColors.statusWarning;
      case WaterQualityStatus.noRecentData:
        return AppColors.secondaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(tank.status);

    return PressableScale(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrivateTankDashboardScreen(tankId: tank.id),
          ),
        );
        onRefresh?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Type Icon + Tank Name + Private lock badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDeepOcean.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTankIcon(tank.tankType),
                    color: AppColors.primaryDeepOcean,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tank.tankName,
                              style: (isDark
                                      ? AppTypography.darkCardTitle
                                      : AppTypography.cardTitle)
                                  .copyWith(fontSize: 15.5, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Private Privacy Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                width: 0.8,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_rounded, size: 11, color: Color(0xFFD97706)),
                                SizedBox(width: 4),
                                Text(
                                  'Private',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${tank.tankType.displayName}${tank.capacityLiters != null ? ' • ${tank.capacityLiters} L' : ''}',
                        style: AppTypography.muted.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Installation Location (owner confirmed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSubtleBg : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primaryDeepOcean),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tank.location.address,
                      style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary)
                          .copyWith(fontSize: 11.5, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Confirmed',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Telemetry quick glance metrics (pH, TDS, Turbidity, Temp)
            Row(
              children: [
                _buildQuickMetric('pH', tank.ph?.toStringAsFixed(1) ?? '--', isDark),
                const SizedBox(width: 8),
                _buildQuickMetric('TDS', tank.tdsEc != null ? '${tank.tdsEc!.toInt()} ppm' : '--', isDark),
                const SizedBox(width: 8),
                _buildQuickMetric('Turbidity', tank.turbidity != null ? '${tank.turbidity!.toStringAsFixed(1)} NTU' : '--', isDark),
                const SizedBox(width: 8),
                _buildQuickMetric('Temp', tank.temperature != null ? '${tank.temperature!.toStringAsFixed(1)}°C' : '--', isDark),
              ],
            ),
            const SizedBox(height: 12),

            // Footer row: Device node connection & last reading timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Device Node status chip
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tank.hasDevice ? AppColors.teal : AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tank.hasDevice
                          ? 'Node: ${tank.deviceId}'
                          : 'No Device Linked',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkMutedText : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                // Status short label & last reading time
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      tank.lastUpdatedFormatted,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkMutedText : AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.secondaryText),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetric(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardSubtleBg : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
