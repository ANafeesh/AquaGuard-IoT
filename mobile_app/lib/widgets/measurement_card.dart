import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/measurement.dart';
import 'status_badge.dart';

class MeasurementCard extends StatelessWidget {
  final ParameterReading reading;
  final VoidCallback? onTap;

  const MeasurementCard({
    super.key,
    required this.reading,
    this.onTap,
  });

  IconData _getIcon(ParameterType type) {
    switch (type) {
      case ParameterType.ph:
        return Icons.water_drop_rounded;
      case ParameterType.tds:
        return Icons.waves_rounded;
      case ParameterType.turbidity:
        return Icons.remove_red_eye_outlined;
      case ParameterType.temperature:
        return Icons.thermostat_rounded;
    }
  }

  Color _getIconColor(ParameterType type) {
    switch (type) {
      case ParameterType.ph:
        return AppColors.primaryAqua;
      case ParameterType.tds:
        return AppColors.teal;
      case ParameterType.turbidity:
        return const Color(0xFF0284C7);
      case ParameterType.temperature:
        return const Color(0xFFEA580C);
    }
  }

  Color _getIconBgColor(ParameterType type) {
    return _getIconColor(type).withValues(alpha: 0.12);
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor(reading.type);
    final iconBgColor = _getIconBgColor(reading.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Icon and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getIcon(reading.type),
                    color: iconColor,
                    size: 20,
                  ),
                ),
                StatusBadge(
                  status: reading.status,
                  isCompact: true,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Middle: Parameter Name
            Text(
              reading.shortName,
              style: AppTypography.secondary.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Value + Unit
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  reading.type == ParameterType.tds
                      ? reading.value.toInt().toString()
                      : reading.value.toStringAsFixed(1),
                  style: AppTypography.measurementValue,
                ),
                if (reading.unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(
                    reading.unit,
                    style: AppTypography.secondary.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ],
            ),

            // Subtle baseline indicator note
            const SizedBox(height: 6),
            Text(
              'Target: ${reading.normalMin} - ${reading.normalMax} ${reading.unit}',
              style: AppTypography.muted.copyWith(
                fontSize: 10.5,
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
