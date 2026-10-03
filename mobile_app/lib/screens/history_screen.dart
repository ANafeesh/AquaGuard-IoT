import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/parameter_thresholds.dart';
import '../models/water_source.dart';
import '../models/measurement.dart';
import '../models/reading_log_entry.dart';
import '../providers/app_state_providers.dart';
import '../providers/repository_providers.dart';
import '../widgets/custom_chart.dart';
import '../widgets/status_badge.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final WaterSource? initialSource;

  const HistoryScreen({super.key, this.initialSource});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  WaterSource? _localSelectedSource;
  ParameterType _selectedParam = ParameterType.ph;
  Map<String, List<HistoricalPoint>> _chartData = const {};
  Map<String, dynamic> _comparison = const {
    'latest': '7.2',
    'previous': '7.1',
    'change': '+0.1',
    'isPositive': true,
  };

  @override
  void initState() {
    super.initState();
    _localSelectedSource = widget.initialSource;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final readingRepo = ref.read(readingRepositoryProvider);
    final active = _localSelectedSource ?? ref.read(activeWaterSourceProvider);
    final sourceId = active?.id ?? 'ws-1';

    final trends = await readingRepo.getHistoricalTrends(sourceId, _selectedParam);
    final delta = await readingRepo.getReadingDelta(sourceId, _selectedParam);

    if (mounted) {
      setState(() {
        _chartData = trends;
        _comparison = delta;
      });
    }
  }

  String get _paramName {
    switch (_selectedParam) {
      case ParameterType.ph:
        return ParameterThresholds.phLabel;
      case ParameterType.tds:
        return ParameterThresholds.tdsLabel;
      case ParameterType.turbidity:
        return ParameterThresholds.turbidityLabel;
      case ParameterType.temperature:
        return ParameterThresholds.tempLabel;
    }
  }

  String get _paramUnit {
    switch (_selectedParam) {
      case ParameterType.ph:
        return ParameterThresholds.phUnit;
      case ParameterType.tds:
        return ParameterThresholds.tdsUnit;
      case ParameterType.turbidity:
        return ParameterThresholds.turbidityUnit;
      case ParameterType.temperature:
        return ParameterThresholds.tempUnit;
    }
  }

  void _showSourcePicker(List<WaterSource> allSources, WaterSource currentSource) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Water Source', style: AppTypography.sectionHeading),
                const SizedBox(height: 12),
                ...allSources.map((source) {
                  final isSelected = source.id == currentSource.id;
                  return ListTile(
                    title: Text(source.name, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                    subtitle: Text(source.coordinates, style: AppTypography.muted),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryAqua) : null,
                    onTap: () {
                      setState(() {
                        _localSelectedSource = source;
                      });
                      ref.read(selectedSourceIdProvider.notifier).setSourceId(source.id);
                      _loadData();
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(waterSourcesStreamProvider);
    final activeGlobal = ref.watch(activeWaterSourceProvider);

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Water Quality History'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
      ),
      body: SafeArea(
        child: sourcesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAqua),
          ),
          error: (e, _) => Center(child: Text('Error loading history: $e')),
          data: (allSources) {
            final currentSource = _localSelectedSource ?? activeGlobal ?? allSources.first;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Water Source Dropdown Selector
                  InkWell(
                    onTap: () => _showSourcePicker(allSources, currentSource),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.water_drop_rounded, color: AppColors.primaryAqua, size: 20),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Selected Source', style: AppTypography.muted.copyWith(fontSize: 10.5)),
                                  Text(
                                    currentSource.name,
                                    style: AppTypography.cardTitle.copyWith(fontSize: 15),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.secondaryText),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Parameter Selector Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _paramTab(ParameterType.ph, ParameterThresholds.phShortLabel),
                        _paramTab(ParameterType.tds, ParameterThresholds.tdsShortLabel),
                        _paramTab(ParameterType.turbidity, ParameterThresholds.turbidityShortLabel),
                        _paramTab(ParameterType.temperature, ParameterThresholds.tempShortLabel),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Large Interactive Trend Chart
                  if (_chartData.isNotEmpty)
                    CustomChartCard(
                      key: ValueKey('${currentSource.id}_${_selectedParam.name}'),
                      title: '$_paramName Trend',
                      subtitle: 'Historical readings aligned with baseline thresholds',
                      dataByRange: _chartData,
                      unit: _paramUnit,
                    ),
                  const SizedBox(height: 16),

                  // Latest vs Previous vs Change Comparison Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reading Delta Comparison',
                              style: AppTypography.cardTitle.copyWith(fontSize: 14.5),
                            ),
                            StatusBadge(status: currentSource.status, isCompact: true),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            // Latest Reading
                            _deltaItem(
                              title: 'Latest Reading',
                              value: '${_comparison['latest']} $_paramUnit',
                              color: AppColors.primaryText,
                            ),
                            _verticalDivider(),
                            // Previous Reading
                            _deltaItem(
                              title: 'Previous Reading',
                              value: '${_comparison['previous']} $_paramUnit',
                              color: AppColors.secondaryText,
                            ),
                            _verticalDivider(),
                            // Change
                            _deltaItem(
                              title: 'Change',
                              value: _comparison['change'] as String? ?? '+0.0',
                              color: AppColors.primaryAqua,
                              isBold: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Measurement Logs
                  Text(
                    'Recent Logged Readings',
                    style: AppTypography.sectionHeading,
                  ),
                  const SizedBox(height: 12),

                  ref.watch(readingLogsStreamProvider(currentSource.id)).when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: AppColors.primaryAqua),
                      ),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Unable to load logs: $e', style: AppTypography.muted),
                    ),
                    data: (logs) {
                      if (logs.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          child: Text(
                            'No logged readings recorded for this source.',
                            style: AppTypography.muted,
                          ),
                        );
                      }

                      return Column(
                        children: logs.map((log) => _buildLogRow(log, currentSource)).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _paramTab(ParameterType type, String title) {
    final isSelected = _selectedParam == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        selected: isSelected,
        label: Text(title),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppColors.primaryText,
        ),
        selectedColor: AppColors.primaryDeepOcean,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.primaryDeepOcean : AppColors.border,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        onSelected: (val) {
          if (val) {
            setState(() {
              _selectedParam = type;
            });
            _loadData();
          }
        },
      ),
    );
  }

  Widget _deltaItem({
    required String title,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Column(
      children: [
        Text(title, style: AppTypography.muted.copyWith(fontSize: 11)),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTypography.measurementValue.copyWith(
            fontSize: 18,
            color: color,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 28, color: AppColors.border);
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes == 0 ? 1 : diff.inMinutes} mins ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildLogRow(ReadingLogEntry log, WaterSource source) {
    return InkWell(
      onTap: () => _showReadingDetailSheet(log, source),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 13, color: AppColors.secondaryText),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(log.timestamp),
                      style: AppTypography.secondary.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'pH ${log.ph.toStringAsFixed(1)} • ${log.tds} ppm • ${log.turbidity.toStringAsFixed(1)} NTU • ${log.temperature.toStringAsFixed(1)}°C',
                  style: AppTypography.muted.copyWith(fontSize: 11),
                ),
              ],
            ),
            Row(
              children: [
                StatusBadge(status: log.status, isCompact: true),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.mutedText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showReadingDetailSheet(ReadingLogEntry log, WaterSource source) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Reading Log Entry', style: AppTypography.sectionHeading),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${source.name} • ${source.coordinates}',
                  style: AppTypography.cardTitle.copyWith(fontSize: 13.5),
                ),
                Text(
                  'Recorded on ${log.timestamp.toString().substring(0, 16)}',
                  style: AppTypography.muted.copyWith(fontSize: 11.5),
                ),
                const SizedBox(height: 16),

                // Telemetry parameters grid
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.mainBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _readingParam('pH', log.ph.toStringAsFixed(1), 'pH', ParameterThresholds.isPhTypical(log.ph)),
                          _readingParam('TDS', '${log.tds}', 'ppm', ParameterThresholds.isTdsTypical(log.tds.toDouble())),
                          _readingParam('Turbidity', log.turbidity.toStringAsFixed(1), 'NTU', ParameterThresholds.isTurbidityTypical(log.turbidity)),
                          _readingParam('Temp', log.temperature.toStringAsFixed(1), '°C', ParameterThresholds.isTempTypical(log.temperature)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Notes & Status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '"${log.notes}"',
                        style: AppTypography.body.copyWith(fontStyle: FontStyle.italic, fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: log.status),
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

  Widget _readingParam(String label, String value, String unit, bool isTypical) {
    return Column(
      children: [
        Text(label, style: AppTypography.muted.copyWith(fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isTypical ? AppColors.primaryText : AppColors.statusWarning,
          ),
        ),
        Text(unit, style: AppTypography.muted.copyWith(fontSize: 9.5)),
      ],
    );
  }
}
