import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../models/community_observation.dart';
import '../../providers/app_state_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';

class MyObservationsScreen extends ConsumerStatefulWidget {
  const MyObservationsScreen({super.key});

  @override
  ConsumerState<MyObservationsScreen> createState() => _MyObservationsScreenState();
}

class _MyObservationsScreenState extends ConsumerState<MyObservationsScreen> {
  String _filterSource = 'All';

  void _showObservationDetail(CommunityObservation obs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Observation Record',
                      style: isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Source and timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      obs.waterSourceName,
                      style: (isDark ? AppTypography.darkLargeTitle : AppTypography.largeTitle).copyWith(fontSize: 20),
                    ),
                    StatusBadge(status: obs.status),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: AppColors.secondaryText),
                    const SizedBox(width: 4),
                    Text(
                      'Reported ${obs.timeAgo} • By ${obs.userName}',
                      style: AppTypography.muted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Parameter Metrics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _metricChip('pH Level', obs.ph?.toStringAsFixed(1) ?? '--', isDark),
                    _metricChip('TDS / EC', '${obs.tds ?? "--"} ppm', isDark),
                    _metricChip('Turbidity', '${obs.turbidity ?? "--"} NTU', isDark),
                    _metricChip('Temp', '${obs.temperature ?? "--"}°C', isDark),
                  ],
                ),
                const SizedBox(height: 16),

                // Qualitative Observation Notes
                if (obs.notes.isNotEmpty) ...[
                  Text(
                    'Field Notes',
                    style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardSubtleBg : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Text(
                      obs.notes,
                      style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Edit Note'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? AppColors.primaryAqua : AppColors.primaryDeepOcean,
                          side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditNoteDialog(obs);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusAttention,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          await ref.read(reportRepositoryProvider).deleteObservation(obs.id);
                          ref.invalidate(observationsStreamProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Observation record deleted.')),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditNoteDialog(CommunityObservation obs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: obs.notes);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Observation Note',
          style: isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle,
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: TextStyle(color: isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
          decoration: InputDecoration(
            hintText: 'Enter observation note...',
            filled: true,
            fillColor: isDark ? AppColors.darkCardSubtleBg : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeepOcean,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newNote = controller.text.trim();
              if (newNote.isNotEmpty) {
                await ref.read(reportRepositoryProvider).updateObservationNote(obs.id, newNote);
                ref.invalidate(observationsStreamProvider);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSubtleBg : AppColors.mainBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: AppTypography.muted.copyWith(fontSize: 10.5, color: isDark ? AppColors.darkMutedText : AppColors.mutedText)),
          const SizedBox(height: 2),
          Text(
            value,
            style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final observationsAsync = ref.watch(observationsStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('My Observations'),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      ),
      body: SafeArea(
        child: observationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAqua),
          ),
          error: (e, _) => Center(child: Text('Error loading observations: $e')),
          data: (allObs) {
            final myObs = allObs.where((obs) {
              if (_filterSource == 'All') return true;
              return obs.waterSourceName.toLowerCase().contains(_filterSource.toLowerCase());
            }).toList();

            if (myObs.isEmpty) {
              return EmptyState(
                icon: Icons.assignment_outlined,
                title: 'No Observations Yet',
                message: 'Submitted field observations will appear here with telemetry snapshots.',
                buttonText: 'Submit Observation',
                onButtonPressed: () => Navigator.pop(context),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Lake View', 'Well', 'River', 'Reservoir'].map((filter) {
                        final isSelected = _filterSource == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(filter),
                            selectedColor: AppColors.primaryAqua,
                            backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryAqua
                                  : (isDark ? AppColors.darkBorder : AppColors.border),
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
                            ),
                            onSelected: (val) {
                              setState(() {
                                _filterSource = filter;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Observations Count Banner
                  Text(
                    '${myObs.length} Submitted Observations',
                    style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading).copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  // Observation List Cards
                  ...myObs.map((obs) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBackground : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () => _showObservationDetail(obs),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAqua.withValues(alpha: isDark ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.water_drop_rounded,
                            color: AppColors.primaryAqua,
                            size: 22,
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                obs.waterSourceName,
                                style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 15),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusBadge(status: obs.status, isCompact: true),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'pH ${obs.ph?.toStringAsFixed(1) ?? '--'} • Turbidity ${obs.turbidity ?? '--'} NTU',
                              style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 12, color: isDark ? AppColors.darkMutedText : AppColors.mutedText),
                                const SizedBox(width: 4),
                                Text(
                                  obs.timeAgo,
                                  style: AppTypography.muted.copyWith(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.sync_rounded, size: 12, color: AppColors.statusNormal),
                                const SizedBox(width: 4),
                                const Text(
                                  'Synced',
                                  style: TextStyle(fontSize: 11, color: AppColors.statusNormal, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
