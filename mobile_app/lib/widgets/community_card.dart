import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/community_observation.dart';
import '../models/water_source.dart';
import 'status_badge.dart';

class CommunityCard extends StatelessWidget {
  final CommunityObservation observation;
  final VoidCallback onTap;

  const CommunityCard({
    super.key,
    required this.observation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1),
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
          // Header: User avatar + name + time + status
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryDeepOcean.withValues(alpha: 0.12),
                child: Text(
                  observation.userAvatar,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDeepOcean,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      observation.userName,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Shared ${observation.timeAgo} • ${observation.waterSourceName}',
                      style: AppTypography.muted.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusBadge(
                status: observation.status,
                isCompact: true,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Observation Notes
          Text(
            '"${observation.notes}"',
            style: AppTypography.body.copyWith(
              fontSize: 13.5,
              fontStyle: FontStyle.italic,
              color: AppColors.primaryText.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),

          // Optional Measurement Tags
          if (observation.ph != null || observation.turbidity != null || observation.tds != null)
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (observation.ph != null)
                  _paramChip('pH ${observation.ph!.toStringAsFixed(1)}'),
                if (observation.turbidity != null)
                  _paramChip('Turbidity ${observation.turbidity!} NTU'),
                if (observation.tds != null)
                  _paramChip('TDS ${observation.tds} ppm'),
                if (observation.hasPhoto)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.mainBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.photo_camera_outlined, size: 12, color: AppColors.secondaryText),
                        SizedBox(width: 4),
                        Text('Photo Attached', style: TextStyle(fontSize: 10.5, color: AppColors.secondaryText)),
                      ],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 12),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_alt_outlined,
                    size: 14,
                    color: AppColors.mutedText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${observation.helpfulCount} community verified',
                    style: AppTypography.muted.copyWith(fontSize: 11),
                  ),
                ],
              ),
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  foregroundColor: AppColors.primaryDeepOcean,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      observation.status != WaterQualityStatus.withinTypicalRange
                          ? 'View Details'
                          : 'View',
                      style: AppTypography.button.copyWith(
                        fontSize: 12.5,
                        color: AppColors.primaryDeepOcean,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paramChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.altLightAquaBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primaryAqua.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.teal,
        ),
      ),
    );
  }
}
