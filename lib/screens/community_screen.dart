import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
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
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Share Observation',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
            letterSpacing: 0.2,
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

            final filtered = allObservations.where((obs) {
              if (_selectedSourceFilter != 'All' && obs.waterSourceName != _selectedSourceFilter) {
                return false;
              }

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

              if (_selectedOriginFilter == 'Device' && !obs.isDeviceSource) return false;
              if (_selectedOriginFilter == 'Community' && obs.isDeviceSource) return false;

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subtitle & Purpose Note
                  Text(
                    'Recent verified IoT device telemetry and crowd-sourced community logs.',
                    style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 1. Sleek Segmented Origin Switcher (All | ESP32 Device | Community)
                  Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBackground : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildSegmentTab(
                          label: 'All Feed (${allObservations.length})',
                          isSelected: _selectedOriginFilter == 'All',
                          onTap: () => setState(() => _selectedOriginFilter = 'All'),
                          isDark: isDark,
                        ),
                        _buildSegmentTab(
                          label: 'ESP32 Device',
                          icon: Icons.memory_rounded,
                          isSelected: _selectedOriginFilter == 'Device',
                          onTap: () => setState(() => _selectedOriginFilter = 'Device'),
                          isDark: isDark,
                        ),
                        _buildSegmentTab(
                          label: 'Community',
                          icon: Icons.people_rounded,
                          isSelected: _selectedOriginFilter == 'Community',
                          onTap: () => setState(() => _selectedOriginFilter = 'Community'),
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. Streamlined Single Row Filter Chips (Source Types)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All Types', 'River', 'Well', 'Reservoir', 'Lake', 'Stream'].map((type) {
                        final isSel = (_selectedTypeFilter == 'All' && type == 'All Types') ||
                            _selectedTypeFilter == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTypeFilter = type == 'All Types' ? 'All' : type;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSel
                                    ? AppColors.primaryDeepOcean
                                    : (isDark ? AppColors.darkCardBackground : Colors.white),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSel
                                      ? AppColors.primaryDeepOcean
                                      : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
                                  width: 0.9,
                                ),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                  color: isSel
                                      ? Colors.white
                                      : (isDark ? AppColors.darkSecondaryText : AppColors.secondaryText),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // List of filtered observations
                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.filter_list_off_rounded, size: 40, color: AppColors.mutedText),
                          const SizedBox(height: 10),
                          Text(
                            'No readings match your filter',
                            style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 14.5),
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

                  // Generous bottom spacing for FAB and Bottom Nav Bar
                  const SizedBox(height: 105),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSegmentTab({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primaryDeepOcean : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primaryDeepOcean)
                      : (isDark ? AppColors.darkMutedText : AppColors.secondaryText),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primaryDeepOcean)
                      : (isDark ? AppColors.darkMutedText : AppColors.secondaryText),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingCard(BuildContext context, CommunityObservation obs, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: obs.isPendingSync
              ? Colors.amber.shade400
              : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          width: obs.isPendingSync ? 1.5 : 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ObservationDetailScreen(observation: obs)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with User/Device badge + Time + Status
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: obs.isDeviceSource
                          ? AppColors.teal.withValues(alpha: 0.15)
                          : AppColors.primaryDeepOcean.withValues(alpha: 0.12),
                      child: Icon(
                        obs.isDeviceSource ? Icons.memory_rounded : Icons.person_rounded,
                        size: 17,
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
                                  borderRadius: BorderRadius.circular(6),
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
                          const SizedBox(height: 1),
                          Text(
                            '${obs.waterSourceName} • ${obs.timeAgo}',
                            style: AppTypography.muted.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: obs.status, isCompact: true),
                  ],
                ),
                const SizedBox(height: 10),

                // Note with refined quote container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSubtleBg : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border(
                      left: BorderSide(
                        color: obs.isDeviceSource ? AppColors.teal : AppColors.primaryAqua,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    obs.notes,
                    style: (isDark ? AppTypography.darkObservationNote : AppTypography.observationNote).copyWith(
                      fontSize: 13.5,
                      height: 1.4,
                      fontStyle: FontStyle.normal,
                      color: isDark ? AppColors.darkPrimaryText : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Parameter metric badges
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    if (obs.ph != null)
                      _metricBadge('pH', obs.ph!.toStringAsFixed(2), const Color(0xFF0284C7), isDark),
                    if (obs.tds != null)
                      _metricBadge('TDS', '${obs.tds} ppm', AppColors.teal, isDark),
                    if (obs.turbidity != null)
                      _metricBadge('Turbidity', '${obs.turbidity!.toStringAsFixed(1)} NTU', const Color(0xFFD97706), isDark),
                    if (obs.temperature != null)
                      _metricBadge('Temp', '${obs.temperature!.toStringAsFixed(1)}°C', const Color(0xFFEA580C), isDark),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricBadge(String label, String value, Color accentColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.35 : 0.22),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkMutedText : const Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
