import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../constants/parameter_thresholds.dart';
import '../../models/community_observation.dart';
import '../../providers/app_state_providers.dart';
import '../../providers/repository_providers.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/primary_button.dart';

class ObservationDetailScreen extends ConsumerStatefulWidget {
  final CommunityObservation observation;

  const ObservationDetailScreen({super.key, required this.observation});

  @override
  ConsumerState<ObservationDetailScreen> createState() => _ObservationDetailScreenState();
}

class _ObservationDetailScreenState extends ConsumerState<ObservationDetailScreen> {
  static const String _upvotedKey = 'user_upvoted_obs_ids';
  bool _isUpvoted = false;

  @override
  void initState() {
    super.initState();
    final upvotedIds = LocalStorageService.instance.getStringList(_upvotedKey);
    _isUpvoted = upvotedIds.contains(widget.observation.id);
  }

  Future<void> _handleUpvote() async {
    if (_isUpvoted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already verified this observation.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    await ref.read(reportRepositoryProvider).upvoteObservation(widget.observation.id);

    final upvotedIds = LocalStorageService.instance.getStringList(_upvotedKey);
    final updatedList = List<String>.from(upvotedIds)..add(widget.observation.id);
    await LocalStorageService.instance.setStringList(_upvotedKey, updatedList);

    if (mounted) {
      setState(() {
        _isUpvoted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Observation verified! Thank you for validating community data.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch observations stream to get reactive helpfulCount
    final allObsAsync = ref.watch(observationsStreamProvider);
    final currentObs = allObsAsync.when(
      data: (list) => list.firstWhere(
        (o) => o.id == widget.observation.id,
        orElse: () => widget.observation,
      ),
      loading: () => widget.observation,
      error: (e, st) => widget.observation,
    );

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Observation Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            currentObs.waterSourceName,
                            style: AppTypography.sectionHeading.copyWith(fontSize: 18),
                          ),
                        ),
                        StatusBadge(status: currentObs.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.secondaryText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            currentObs.locationArea,
                            style: AppTypography.muted.copyWith(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppColors.border),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primaryDeepOcean.withValues(alpha: 0.12),
                          child: Text(
                            currentObs.userAvatar,
                            style: const TextStyle(
                              fontSize: 13,
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
                                currentObs.userName,
                                style: AppTypography.cardTitle.copyWith(fontSize: 14),
                              ),
                              Text(
                                'Reported ${currentObs.timeAgo}',
                                style: AppTypography.muted.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.altLightAquaBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isUpvoted ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                size: 14,
                                color: AppColors.teal,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${currentObs.helpfulCount} Verified',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Notes Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Observer Notes', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      '"${currentObs.notes}"',
                      style: AppTypography.body.copyWith(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Measurements Grid
              if (currentObs.ph != null ||
                  currentObs.tds != null ||
                  currentObs.turbidity != null ||
                  currentObs.temperature != null) ...[
                Text('Recorded Readings', style: AppTypography.sectionHeading.copyWith(fontSize: 16)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.7,
                  children: [
                    if (currentObs.ph != null)
                      _buildMetricCard(
                        ParameterThresholds.phLabel,
                        currentObs.ph!.toStringAsFixed(1),
                        'pH',
                        ParameterThresholds.isPhTypical(currentObs.ph!),
                      ),
                    if (currentObs.tds != null)
                      _buildMetricCard(
                        ParameterThresholds.tdsLabel,
                        '${currentObs.tds}',
                        ParameterThresholds.tdsUnit,
                        ParameterThresholds.isTdsTypical(currentObs.tds!.toDouble()),
                      ),
                    if (currentObs.turbidity != null)
                      _buildMetricCard(
                        ParameterThresholds.turbidityLabel,
                        currentObs.turbidity!.toStringAsFixed(1),
                        ParameterThresholds.turbidityUnit,
                        ParameterThresholds.isTurbidityTypical(currentObs.turbidity!),
                      ),
                    if (currentObs.temperature != null)
                      _buildMetricCard(
                        ParameterThresholds.tempLabel,
                        currentObs.temperature!.toStringAsFixed(1),
                        ParameterThresholds.tempUnit,
                        ParameterThresholds.isTempTypical(currentObs.temperature!),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
              ],

              // Photo Evidence Section
              if (currentObs.hasPhoto) ...[
                Text('Photo Evidence', style: AppTypography.sectionHeading.copyWith(fontSize: 16)),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.altLightAquaBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.water_drop_rounded, size: 48, color: AppColors.primaryAqua.withValues(alpha: 0.6)),
                          const SizedBox(height: 8),
                          Text(
                            'Water sample specimen photo',
                            style: AppTypography.secondary.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verified sample attached at site',
                            style: AppTypography.muted.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Upvote Action Button
              PrimaryButton(
                text: _isUpvoted ? 'Observation Verified (+1)' : 'Verify Observation',
                icon: _isUpvoted ? Icons.check_circle_rounded : Icons.thumb_up_alt_rounded,
                color: _isUpvoted ? AppColors.statusNormal : AppColors.primaryDeepOcean,
                onPressed: _handleUpvote,
              ),
              const SizedBox(height: 16),

              // Disclaimer Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.altLightAquaBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Community observations are submitted by registered citizen observers. Upvoting indicates verification or corroboration of local site conditions.',
                        style: AppTypography.secondary.copyWith(
                          color: AppColors.teal,
                          fontSize: 11.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, String unit, bool isTypical) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isTypical ? AppColors.border : AppColors.statusWarning.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTypography.muted.copyWith(fontSize: 11)),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTypical ? AppColors.statusNormal : AppColors.statusWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.measurementValue.copyWith(fontSize: 18),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: AppTypography.muted.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
