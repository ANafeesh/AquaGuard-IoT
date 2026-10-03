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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                    Text('Observation Record', style: AppTypography.sectionHeading),
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
                    Text(obs.waterSourceName, style: AppTypography.largeTitle.copyWith(fontSize: 20)),
                    StatusBadge(status: obs.status),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: AppColors.secondaryText),
                    const SizedBox(width: 4),
                    Text(obs.timeAgo, style: AppTypography.muted),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.secondaryText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        obs.locationArea,
                        style: AppTypography.muted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Simulated Mini-Map Preview
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EFE9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        right: 20,
                        bottom: 10,
                        child: Container(
                          width: 80,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFBAE6FD),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_pin, color: AppColors.primaryDeepOcean, size: 28),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              obs.locationArea,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Recorded Readings
                Text('Recorded Readings', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricChip('pH', obs.ph?.toStringAsFixed(1) ?? 'N/A'),
                    _metricChip('TDS', '${obs.tds ?? '--'} ppm'),
                    _metricChip('Turbidity', '${obs.turbidity ?? '--'} NTU'),
                    _metricChip('Temp', '${obs.temperature ?? '--'} °C'),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                Text('Observation Notes', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  obs.notes,
                  style: AppTypography.body.copyWith(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 20),

                // Actions: Edit and Delete
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.statusAttention,
                          side: const BorderSide(color: AppColors.statusAttention),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Delete'),
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmDelete(obs);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDeepOcean,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Note'),
                        onPressed: () {
                          Navigator.pop(context);
                          _editNote(obs);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(CommunityObservation obs) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Delete Observation?'),
        content: Text('Are you sure you want to remove your observation for "${obs.waterSourceName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusAttention,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(reportRepositoryProvider).deleteObservation(obs.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Observation deleted from records.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _editNote(CommunityObservation obs) {
    final noteController = TextEditingController(text: obs.notes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Edit Observation Note'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Update observation notes...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeepOcean,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newNote = noteController.text.trim();
              Navigator.pop(context);
              if (newNote.isNotEmpty) {
                await ref.read(reportRepositoryProvider).updateObservationNote(obs.id, newNote);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Observation note updated successfully.')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mainBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: AppTypography.muted.copyWith(fontSize: 10.5)),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.secondary.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final observationsAsync = ref.watch(observationsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('My Observations'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
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
              return obs.waterSourceName.contains(_filterSource);
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
                      children: ['All', 'Lake View', 'Well', 'Riverside'].map((filter) {
                        final isSelected = _filterSource == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(filter),
                            selectedColor: AppColors.primaryAqua,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryAqua : AppColors.border,
                            ),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.primaryText,
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
                    style: AppTypography.sectionHeading.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  // Observation List Cards
                  ...myObs.map((obs) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
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
                            color: AppColors.primaryAqua.withValues(alpha: 0.12),
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
                            Text(obs.waterSourceName, style: AppTypography.cardTitle.copyWith(fontSize: 15)),
                            StatusBadge(status: obs.status, isCompact: true),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'pH ${obs.ph?.toStringAsFixed(1) ?? '--'} • Turbidity ${obs.turbidity ?? '--'} NTU',
                              style: AppTypography.secondary.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 12, color: AppColors.mutedText),
                                const SizedBox(width: 4),
                                Text(obs.timeAgo, style: AppTypography.muted.copyWith(fontSize: 11)),
                                const SizedBox(width: 10),
                                const Icon(Icons.sync_rounded, size: 12, color: AppColors.statusNormal),
                                const SizedBox(width: 4),
                                Text('Synced', style: AppTypography.muted.copyWith(fontSize: 11, color: AppColors.statusNormal)),
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
