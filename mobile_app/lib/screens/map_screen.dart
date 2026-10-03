import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/water_source.dart';
import '../providers/app_state_providers.dart';
import '../providers/saved_sources_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/primary_button.dart';
import '../widgets/interactive_map_widget.dart';
import 'water_source_details_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String _selectedFilter = 'All';
  String _selectedRadius = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WaterSource> _applyFilter(List<WaterSource> sources) {
    return sources.where((source) {
      if (_selectedFilter == 'Typical' && source.status != WaterQualityStatus.withinTypicalRange) {
        return false;
      }
      if (_selectedFilter == 'Unusual' && source.status != WaterQualityStatus.unusual) {
        return false;
      }
      if (_selectedFilter == 'No Data' && source.status != WaterQualityStatus.noRecentData) {
        return false;
      }
      if (_searchController.text.trim().isNotEmpty) {
        final query = _searchController.text.trim().toLowerCase();
        return source.name.toLowerCase().contains(query) ||
            source.locationArea.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  void _showFilterOptionsSheet() {
    final currentStyle = ref.read(userPreferencesProvider).mapStyle;
    String tempStyle = currentStyle;
    String tempFilter = _selectedFilter;
    String tempRadius = _selectedRadius;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Map & Filter Options', style: AppTypography.sectionHeading),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Map Style Layer Selector
                    Text('Map Style Layer', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Standard', 'Satellite', 'Terrain'].map((style) {
                        final isSel = tempStyle == style;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(style),
                            selected: isSel,
                            selectedColor: AppColors.primaryDeepOcean,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? Colors.white : AppColors.primaryText,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSel ? AppColors.primaryDeepOcean : AppColors.border,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => tempStyle = style);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Status Filter
                    Text('Quality Status Filter', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['All', 'Typical', 'Unusual', 'No Data'].map((filter) {
                        final isSel = tempFilter == filter;
                        return ChoiceChip(
                          label: Text(filter),
                          selected: isSel,
                          selectedColor: AppColors.primaryAqua,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : AppColors.primaryText,
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSel ? AppColors.primaryAqua : AppColors.border,
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => tempFilter = filter);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Search Radius
                    Text('Monitoring Radius', style: AppTypography.cardTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 8),
                    Row(
                      children: ['All', '5 km', '10 km', '25 km'].map((radius) {
                        final isSel = tempRadius == radius;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(radius),
                            selected: isSel,
                            selectedColor: AppColors.teal,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              color: isSel ? Colors.white : AppColors.primaryText,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSel ? AppColors.teal : AppColors.border,
                            ),
                            onSelected: (val) {
                              if (val) setModalState(() => tempRadius = radius);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Apply Button
                    PrimaryButton(
                      text: 'Apply Filters',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: () {
                        ref.read(userPreferencesProvider.notifier).setMapStyle(tempStyle);
                        setState(() {
                          _selectedFilter = tempFilter;
                          _selectedRadius = tempRadius;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(waterSourcesStreamProvider);
    final activeSource = ref.watch(activeWaterSourceProvider);
    final currentMapStyle = ref.watch(userPreferencesProvider).mapStyle;
    final savedIds = ref.watch(savedSourceIdsProvider);

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: SafeArea(
        child: sourcesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAqua),
          ),
          error: (err, _) => Center(
            child: Text('Error loading map data: $err'),
          ),
          data: (allSources) {
            final filtered = _applyFilter(allSources);
            final selected = activeSource ?? allSources.first;
            final isSaved = savedIds.contains(selected.id);

            return Stack(
              children: [
                // Interactive Map Widget
                Positioned.fill(
                  child: InteractiveMapWidget(
                    waterSources: filtered,
                    selectedSource: selected,
                    mapStyle: currentMapStyle,
                    onSourceSelected: (source) {
                      ref.read(selectedSourceIdProvider.notifier).setSourceId(source.id);
                    },
                  ),
                ),

                // Top Floating Search Bar and Filter Chips
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      // Search Bar Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search water sources...',
                            hintStyle: AppTypography.secondary.copyWith(
                              color: AppColors.mutedText,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.primaryDeepOcean,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.tune_rounded, size: 18, color: AppColors.teal),
                                        onPressed: _showFilterOptionsSheet,
                                      ),
                                    ],
                                  )
                                : InkWell(
                                    onTap: _showFilterOptionsSheet,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.altLightAquaBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.tune_rounded,
                                        size: 18,
                                        color: AppColors.teal,
                                      ),
                                    ),
                                  ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'Typical', 'Unusual', 'No Data'].map((filter) {
                            final isSelected = _selectedFilter == filter;
                            Color chipColor = AppColors.primaryDeepOcean;
                            if (filter == 'Typical') chipColor = AppColors.statusNormal;
                            if (filter == 'Unusual') chipColor = AppColors.statusWarning;
                            if (filter == 'No Data') chipColor = AppColors.secondaryText;

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
                                selectedColor: chipColor,
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected ? chipColor : AppColors.border,
                                ),
                                elevation: 2,
                                shadowColor: Colors.black.withValues(alpha: 0.1),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                    ],
                  ),
                ),

                // Draggable Bottom Sheet Card for Selected Location
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(selected.id),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.border, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Drag handle bar
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),

                          // Location Header & Status Badge + Bookmark button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selected.name,
                                      style: AppTypography.sectionHeading.copyWith(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      selected.coordinates,
                                      style: AppTypography.muted.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: isSaved ? 'Remove Bookmark' : 'Bookmark Source',
                                    icon: Icon(
                                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                      color: isSaved ? AppColors.teal : AppColors.mutedText,
                                    ),
                                    onPressed: () {
                                      ref.read(savedSourceIdsProvider.notifier).toggleBookmark(selected.id);
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  StatusBadge(status: selected.status),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Key Indicator Metrics
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.mainBackground,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _miniMetric('pH', selected.ph.toStringAsFixed(1)),
                                _metricSeparator(),
                                _miniMetric('TDS', '${selected.tds} ppm'),
                                _metricSeparator(),
                                _miniMetric('Turbidity', '${selected.turbidity} NTU'),
                                _metricSeparator(),
                                _miniMetric('Temp', '${selected.temperature}°C'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Action Button
                          PrimaryButton(
                            text: 'View Details',
                            icon: Icons.analytics_outlined,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WaterSourceDetailsScreen(
                                    waterSource: selected,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _miniMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppTypography.muted.copyWith(fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.secondary.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  Widget _metricSeparator() {
    return Container(width: 1, height: 22, color: AppColors.border);
  }
}
