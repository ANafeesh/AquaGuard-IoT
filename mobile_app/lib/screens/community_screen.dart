import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../providers/app_state_providers.dart';
import '../widgets/community_card.dart';
import 'community/observation_detail_screen.dart';
import 'report_measurement_screen.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String _selectedFilter = 'All';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final observationsAsync = ref.watch(observationsStreamProvider);
    final sourcesAsync = ref.watch(waterSourcesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by source, note, or observer...',
                  hintStyle: AppTypography.secondary.copyWith(color: AppColors.mutedText, fontSize: 13.5),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 14.5),
              )
            : const Text('Community'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        actions: [
          if (_isSearching) ...[
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _isSearching = false;
                });
              },
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReportMeasurementScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primaryDeepOcean,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Share Observation',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: observationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAqua),
          ),
          error: (e, _) => Center(child: Text('Error loading observations: $e')),
          data: (allObservations) {
            // Dynamic filter options generated from actual water sources
            final availableSources = sourcesAsync.value ?? [];
            final dynamicFilterOptions = ['All', ...availableSources.map((s) => s.name)];

            final query = _searchController.text.trim().toLowerCase();

            final observations = allObservations.where((obs) {
              // Source filter chip
              if (_selectedFilter != 'All' && obs.waterSourceName != _selectedFilter) {
                return false;
              }

              // Keyword search filter
              if (query.isNotEmpty) {
                final matchSource = obs.waterSourceName.toLowerCase().contains(query);
                final matchNotes = obs.notes.toLowerCase().contains(query);
                final matchUser = obs.userName.toLowerCase().contains(query);
                final matchLocation = obs.locationArea.toLowerCase().contains(query);
                if (!matchSource && !matchNotes && !matchUser && !matchLocation) {
                  return false;
                }
              }

              return true;
            }).toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Subtitle
                  Text(
                    'Explore observations shared by citizen observers and field testing teams.',
                    style: AppTypography.secondary.copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: 14),

                  // Dynamic Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: dynamicFilterOptions.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(filter),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppColors.primaryText,
                            ),
                            selectedColor: AppColors.primaryDeepOcean,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryDeepOcean : AppColors.border,
                            ),
                            onSelected: (val) {
                              setState(() {
                                _selectedFilter = filter;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  if (observations.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: AppColors.mutedText),
                          const SizedBox(height: 12),
                          Text(
                            'No matching observations found',
                            style: AppTypography.cardTitle.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try adjusting your search keywords or filter selection.',
                            style: AppTypography.muted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    // Community Observation Cards List
                    ...observations.map((obs) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: CommunityCard(
                          observation: obs,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ObservationDetailScreen(observation: obs),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
