import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../models/water_source.dart';
import '../models/community_observation.dart';
import '../providers/app_state_providers.dart';
import '../widgets/status_badge.dart';
import 'report_measurement_screen.dart';
import 'community/observation_detail_screen.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String _selectedSourceFilter = 'All';
  String _selectedTypeFilter = 'All'; // 'All', 'River', 'Well', 'Reservoir', 'Lake', 'Stream'
  String _selectedOriginFilter = 'All'; // 'All', 'Device', 'Community'
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final observationsAsync = ref.watch(observationsStreamProvider);
    final sourcesAsync = ref.watch(waterSourcesStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search observations, notes, locations...',
                  hintStyle: AppTypography.muted.copyWith(fontSize: 13.5),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontSize: 14.5,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
                ),
              )
            : const Text('Community Water Feed'),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
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
                setState(() => _isSearching = false);
              },
            ),
          ] else
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => setState(() => _isSearching = true),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('community_share_observation_fab'),
        heroTag: 'community_feed_fab',
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
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: observationsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAqua),
          ),
          error: (e, _) => Center(child: Text('Error loading feed: $e')),
          data: (allObservations) {
            final availableSources = sourcesAsync.value ?? [];
            final query = _searchController.text.trim().toLowerCase();

            // Filter by search query, source, source type, and origin
            final filtered = allObservations.where((obs) {
              // 1. Source filter
              if (_selectedSourceFilter != 'All' && obs.waterSourceName != _selectedSourceFilter) {
                return false;
              }

              // 2. Source Type filter
              if (_selectedTypeFilter != 'All') {
                final matchedSource = availableSources.where((s) => s.name == obs.waterSourceName).firstOrNull;
                if (matchedSource != null) {
                  if (matchedSource.type.displayName.toLowerCase() != _selectedTypeFilter.toLowerCase()) {
                    return false;
                  }
                } else if (!obs.waterSourceName.toLowerCase().contains(_selectedTypeFilter.toLowerCase())) {
                  return false;
                }
              }

              // 3. Origin filter (Device vs Community)
              if (_selectedOriginFilter == 'Device' && !obs.isDeviceSource) return false;
              if (_selectedOriginFilter == 'Community' && obs.isDeviceSource) return false;

              // 4. Keyword query
              if (query.isNotEmpty) {
                final matchSource = obs.waterSourceName.toLowerCase().contains(query);
                final matchNotes = obs.notes.toLowerCase().contains(query);
                final matchUser = obs.userName.toLowerCase().contains(query);
                final matchLoc = obs.locationArea.toLowerCase().contains(query);
                if (!matchSource && !matchNotes && !matchUser && !matchLoc) return false;
              }

              return true;
            }).toList();

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle & Purpose Note
                  Text(
                    'Recent verified IoT device telemetry and crowd-sourced community logs.',
                    style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // Origin Toggle Row (All | ESP32 Device | Community)
                  Row(
                    children: [
                      _buildChip(
                        label: 'All Feed (${allObservations.length})',
                        isSelected: _selectedOriginFilter == 'All',
                        onTap: () => setState(() => _selectedOriginFilter = 'All'),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: 'ESP32 Device',
                        icon: Icons.memory_rounded,
                        isSelected: _selectedOriginFilter == 'Device',
                        onTap: () => setState(() => _selectedOriginFilter = 'Device'),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildChip(
                        label: 'Community',
                        icon: Icons.people_outline_rounded,
                        isSelected: _selectedOriginFilter == 'Community',
                        onTap: () => setState(() => _selectedOriginFilter = 'Community'),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Filter by Source Type (All, River, Well, Reservoir, Lake, Stream)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All Types', 'River', 'Well', 'Reservoir', 'Lake', 'Stream'].map((type) {
                        final isSel = (_selectedTypeFilter == 'All' && type == 'All Types') ||
                            _selectedTypeFilter == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(type),
                            selected: isSel,
                            selectedColor: AppColors.primaryDeepOcean,
                            backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
                            labelStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? Colors.white : (isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
                            ),
                            side: BorderSide(
                              color: isSel ? AppColors.primaryDeepOcean : (isDark ? AppColors.darkBorder : AppColors.border),
                            ),
                            onSelected: (val) {
                              setState(() {
                                _selectedTypeFilter = type == 'All Types' ? 'All' : type;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Filter by Monitored Source Name
                  if (availableSources.isNotEmpty)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All Sources', ...availableSources.map((s) => s.name)].map((sourceName) {
                          final isSel = (_selectedSourceFilter == 'All' && sourceName == 'All Sources') ||
                              _selectedSourceFilter == sourceName;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(sourceName),
                              selected: isSel,
                              selectedColor: AppColors.teal,
                              backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                color: isSel ? Colors.white : (isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                              ),
                              side: BorderSide(
                                color: isSel ? AppColors.teal : (isDark ? AppColors.darkBorder : AppColors.border),
                              ),
                              onSelected: (val) {
                                setState(() {
                                  _selectedSourceFilter = sourceName == 'All Sources' ? 'All' : sourceName;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // List of filtered observations
                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(36),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.filter_list_off_rounded, size: 44, color: AppColors.mutedText),
                          const SizedBox(height: 12),
                          Text(
                            'No readings match your filter',
                            style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try selecting "All Types" or clearing search keywords.',
                            style: AppTypography.muted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    ...filtered.map((obs) => _buildReadingCard(context, obs, isDark)),

                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryDeepOcean
              : (isDark ? AppColors.darkCardBackground : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryDeepOcean
                : (isDark ? AppColors.darkBorder : AppColors.border),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : (isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingCard(BuildContext context, CommunityObservation obs, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: obs.isPendingSync
              ? Colors.amber.shade400
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: obs.isPendingSync ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ObservationDetailScreen(observation: obs)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with User/Device badge + Time + Status
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: obs.isDeviceSource
                      ? AppColors.teal.withValues(alpha: 0.15)
                      : AppColors.primaryDeepOcean.withValues(alpha: 0.12),
                  child: Icon(
                    obs.isDeviceSource ? Icons.memory_rounded : Icons.person_rounded,
                    size: 18,
                    color: obs.isDeviceSource ? AppColors.teal : AppColors.primaryDeepOcean,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              obs.userName,
                              style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: obs.isDeviceSource
                                  ? (isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1))
                                  : (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              obs.isDeviceSource ? 'ESP32 Device' : 'Community',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: obs.isDeviceSource
                                    ? (isDark ? Colors.teal.shade200 : AppColors.teal)
                                    : (isDark ? Colors.blue.shade200 : AppColors.primaryDeepOcean),
                              ),
                            ),
                          ),
                          if (obs.isPendingSync) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Pending sync',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF78350F),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '${obs.waterSourceName} • ${obs.timeAgo}',
                        style: AppTypography.muted.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: obs.status, isCompact: true),
              ],
            ),
            const SizedBox(height: 10),

            // Note
            Text(
              '"${obs.notes}"',
              style: (isDark ? AppTypography.darkBody : AppTypography.body).copyWith(
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),

            // Metric pills
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (obs.ph != null) _paramTag('pH', obs.ph!.toStringAsFixed(2), isDark),
                if (obs.tds != null) _paramTag('TDS', '${obs.tds} ppm', isDark),
                if (obs.turbidity != null) _paramTag('Turbidity', '${obs.turbidity!.toStringAsFixed(1)} NTU', isDark),
                if (obs.temperature != null) _paramTag('Temp', '${obs.temperature!.toStringAsFixed(1)}°C', isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paramTag(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardSubtleBg : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
        ),
      ),
    );
  }
}
