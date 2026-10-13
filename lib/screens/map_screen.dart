import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../models/water_source.dart';
import '../providers/app_state_providers.dart';
import '../providers/saved_sources_provider.dart';
import '../providers/user_preferences_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/interactive_map_widget.dart';
import 'water_source_details_screen.dart';
import 'history_screen.dart';
import 'report_measurement_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  static bool defaultUseOpenStreetMap = true;

  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  String _selectedFilter = 'All';
  late bool _useOpenStreetMap = MapScreen.defaultUseOpenStreetMap;
  final TextEditingController _searchController = TextEditingController();
  final MapController _mapController = MapController();

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
            source.type.displayName.toLowerCase().contains(query);
      }
      return true;
    }).toList();
  }

  Color _getMarkerStatusColor(WaterQualityStatus status) {
    switch (status) {
      case WaterQualityStatus.withinTypicalRange:
        return AppColors.teal;
      case WaterQualityStatus.unusual:
        return AppColors.statusWarning;
      case WaterQualityStatus.noRecentData:
        return AppColors.secondaryText;
    }
  }

  void _showSourceBottomSheet(WaterSource source) {
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Source Name, Type, and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAqua.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  source.type.displayName,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDeepOcean,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                source.lastUpdated,
                                style: AppTypography.muted.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            source.name,
                            style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading).copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'GPS: ${source.coordinates}',
                            style: AppTypography.muted.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status: source.status),
                  ],
                ),
                const SizedBox(height: 16),

                // Key Indicator Metrics
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSubtleBg : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _miniMetric('pH Level', source.ph?.toStringAsFixed(1) ?? '--', isDark),
                      _metricSeparator(),
                      _miniMetric('TDS / EC', '${source.tds} ppm', isDark),
                      _metricSeparator(),
                      _miniMetric('Turbidity', '${source.turbidity?.toStringAsFixed(1) ?? "--"} NTU', isDark),
                      _metricSeparator(),
                      _miniMetric('Temp', '${source.temperature?.toStringAsFixed(1) ?? "--"}°C', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Buttons: View history & View details
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.show_chart_rounded, size: 18),
                        label: const Text('View history', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryAqua,
                          side: const BorderSide(color: AppColors.primaryAqua, width: 1.3),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HistoryScreen(initialSource: source),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: const Text('Source Details', style: TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDeepOcean,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WaterSourceDetailsScreen(waterSource: source),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sourcesAsync = ref.watch(waterSourcesStreamProvider);
    final activeSource = ref.watch(activeWaterSourceProvider);
    final savedSourceIds = ref.watch(savedSourceIdsProvider);
    final currentMapStyle = ref.watch(userPreferencesProvider).mapStyle;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      body: SafeArea(
        child: sourcesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAqua),
          ),
          error: (err, _) => Center(child: Text('Error loading map: $err')),
          data: (allSources) {
            final visibleSources = _applyFilter(allSources);
            final selected = activeSource ?? (allSources.isNotEmpty ? allSources.first : null);
            final isSaved = selected != null && savedSourceIds.contains(selected.id);

            return Stack(
              children: [
                // Interactive Map Layer (OpenStreetMap Flutter Map or Vector Canvas)
                if (_useOpenStreetMap && allSources.isNotEmpty)
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        selected?.latitude ?? 6.9271,
                        selected?.longitude ?? 79.8612,
                      ),
                      initialZoom: 13.0,
                      minZoom: 4.0,
                      maxZoom: 18.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'io.aquaguard.app',
                        errorTileCallback: (tile, error, stackTrace) {},
                      ),
                      MarkerLayer(
                        markers: visibleSources.map((source) {
                          final isCurrent = source.id == selected?.id;
                          final markerColor = _getMarkerStatusColor(source.status);

                          return Marker(
                            point: LatLng(source.latitude, source.longitude),
                            width: isCurrent ? 54 : 44,
                            height: isCurrent ? 54 : 44,
                            child: GestureDetector(
                              onTap: () {
                                ref.read(selectedSourceIdProvider.notifier).setSourceId(source.id);
                                _showSourceBottomSheet(source);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: markerColor,
                                    width: isCurrent ? 3.5 : 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: markerColor.withValues(alpha: 0.35),
                                      blurRadius: isCurrent ? 12 : 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.water_drop_rounded,
                                    color: markerColor,
                                    size: isCurrent ? 24 : 18,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  )
                else if (allSources.isNotEmpty)
                  InteractiveMapWidget(
                    waterSources: visibleSources,
                    selectedSource: selected ?? allSources.first,
                    mapStyle: currentMapStyle,
                    onSourceSelected: (source) {
                      ref.read(selectedSourceIdProvider.notifier).setSourceId(source.id);
                      _showSourceBottomSheet(source);
                    },
                  ),

                // Top Floating Search & Filter Bar
                Positioned(
                  top: 14,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardBackground : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: AppColors.secondaryText, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  hintText: 'Search river, well, reservoir...',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _useOpenStreetMap ? Icons.layers_rounded : Icons.map_outlined,
                                color: AppColors.primaryAqua,
                              ),
                              tooltip: 'Toggle Map Mode',
                              onPressed: () {
                                setState(() {
                                  _useOpenStreetMap = !_useOpenStreetMap;
                                });
                              },
                            ),
                          ],
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
                                  color: isSelected ? Colors.white : (isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
                                ),
                                selectedColor: chipColor,
                                backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
                                side: BorderSide(
                                  color: isSelected ? chipColor : (isDark ? AppColors.darkBorder : AppColors.border),
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
                    ],
                  ),
                ),

                // Recenter GPS Button
                Positioned(
                  right: 16,
                  bottom: selected != null ? 282 : 76,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter_gps',
                    backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
                    foregroundColor: AppColors.primaryDeepOcean,
                    child: const Icon(Icons.my_location_rounded),
                    onPressed: () {
                      if (selected != null) {
                        _mapController.move(
                          LatLng(selected.latitude, selected.longitude),
                          14.0,
                        );
                      }
                    },
                  ),
                ),

                // Floating Action Button: Add Reading (positioned cleanly above preview card)
                Positioned(
                  bottom: selected != null ? 222 : 16,
                  right: 16,
                  child: FloatingActionButton.extended(
                    key: const Key('add_community_reading_fab'),
                    heroTag: 'map_add_reading_fab',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportMeasurementScreen(
                            preselectedSourceId: activeSource?.id,
                          ),
                        ),
                      );
                    },
                    backgroundColor: AppColors.primaryDeepOcean,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: const Text(
                      'Add reading',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ),

                // Selected Source Quick Preview Card at Bottom
                if (selected != null)
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardBackground : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selected.name,
                                      style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading).copyWith(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${selected.type.displayName} • ${selected.coordinates}',
                                      style: AppTypography.muted.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                      color: isSaved ? AppColors.teal : AppColors.mutedText,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      ref.read(savedSourceIdsProvider.notifier).toggleBookmark(selected.id);
                                    },
                                  ),
                                  StatusBadge(status: selected.status, isCompact: true),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Mini metrics
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardSubtleBg : AppColors.mainBackground,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _miniMetric('pH', selected.ph?.toStringAsFixed(1) ?? '--', isDark),
                                _metricSeparator(),
                                _miniMetric('TDS', '${selected.tds} ppm', isDark),
                                _metricSeparator(),
                                _miniMetric('Turb', '${selected.turbidity?.toStringAsFixed(1) ?? "--"} NTU', isDark),
                                _metricSeparator(),
                                _miniMetric('Temp', '${selected.temperature?.toStringAsFixed(1) ?? "--"}°C', isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Action Buttons: View History & Details
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    foregroundColor: AppColors.primaryAqua,
                                    side: const BorderSide(color: AppColors.primaryAqua),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => HistoryScreen(initialSource: selected)),
                                    );
                                  },
                                  child: const Text('View history', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    backgroundColor: AppColors.primaryDeepOcean,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => WaterSourceDetailsScreen(waterSource: selected)),
                                    );
                                  },
                                  child: const Text('Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _miniMetric(String label, String value, bool isDark) {
    return Column(
      children: [
        Text(label, style: AppTypography.muted.copyWith(fontSize: 10)),
        const SizedBox(height: 1),
        Text(
          value,
          style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _metricSeparator() {
    return Container(width: 1, height: 20, color: AppColors.border);
  }
}
