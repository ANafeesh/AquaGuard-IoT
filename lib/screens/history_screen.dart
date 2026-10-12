import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/config/parameter_thresholds.dart';
import '../core/widgets/disclaimer_banner.dart';
import '../models/water_source.dart';
import '../models/measurement.dart';
import '../providers/app_state_providers.dart';
import '../providers/repository_providers.dart';
import '../features/history/widgets/fl_parameter_chart.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final WaterSource? initialSource;

  const HistoryScreen({super.key, this.initialSource});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  WaterSource? _localSelectedSource;
  ParameterType _selectedParam = ParameterType.ph;
  String _selectedRange = '24h'; // '24h', '7d', '30d', 'All'

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

  Color get _paramColor {
    switch (_selectedParam) {
      case ParameterType.ph:
        return AppColors.primaryAqua;
      case ParameterType.tds:
        return AppColors.teal;
      case ParameterType.turbidity:
        return const Color(0xFF0284C7);
      case ParameterType.temperature:
        return const Color(0xFFEA580C);
    }
  }

  List<HistoricalPoint> _getActivePoints() {
    final rangeKey = _selectedRange.toUpperCase();
    if (_chartData.containsKey(rangeKey)) {
      return _chartData[rangeKey] ?? [];
    }
    // Handle 'All' range or default
    if (rangeKey == 'ALL') {
      // Aggregate all points
      final List<HistoricalPoint> all = [];
      _chartData.forEach((_, list) => all.addAll(list));
      return all;
    }
    return _chartData['24H'] ?? [];
  }

  void _showSourcePicker(List<WaterSource> allSources, WaterSource currentSource) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Select Water Source', style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading)),
                const SizedBox(height: 12),
                ...allSources.map((source) {
                  final isSelected = source.id == currentSource.id;
                  return ListTile(
                    title: Text(
                      source.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
                      ),
                    ),
                    subtitle: Text(source.coordinates, style: AppTypography.muted),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryAqua) : null,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allSources = ref.watch(waterSourcesStreamProvider).value ?? [];
    final active = _localSelectedSource ?? (allSources.isNotEmpty ? allSources.first : null);
    final activePoints = _getActivePoints();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Historical Water Trends'),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source Selector Bar
              if (active != null)
                InkWell(
                  onTap: () => _showSourcePicker(allSources, active),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBackground : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppColors.primaryAqua, size: 20),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  active.name,
                                  style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 15),
                                ),
                                Text(
                                  active.coordinates,
                                  style: AppTypography.muted.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Switch',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryAqua,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryAqua),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),

              // Parameter Selection Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildParamTab(ParameterType.ph, 'pH Level', isDark),
                    const SizedBox(width: 8),
                    _buildParamTab(ParameterType.tds, 'TDS / EC', isDark),
                    const SizedBox(width: 8),
                    _buildParamTab(ParameterType.turbidity, 'Turbidity', isDark),
                    const SizedBox(width: 8),
                    _buildParamTab(ParameterType.temperature, 'Temperature', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // fl_chart Line Chart with Tooltips & "No data for this range" empty handling
              FlParameterChart(
                title: '$_paramName Time Series',
                parameterName: _paramName,
                unit: _paramUnit,
                points: activePoints,
                selectedRange: _selectedRange,
                primaryColor: _paramColor,
                onRangeChanged: (range) {
                  setState(() {
                    _selectedRange = range;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Reading Delta Comparison Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBackground : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Baseline Delta Analysis',
                      style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDeltaItem('Latest Reading', '${_comparison['latest']} $_paramUnit', isDark),
                        _divider(),
                        _buildDeltaItem('Previous Sample', '${_comparison['previous']} $_paramUnit', isDark),
                        _divider(),
                        _buildDeltaItem('Net Change', '${_comparison['change']} $_paramUnit', isDark, highlight: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Regulatory Notice
              const DisclaimerBanner(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParamTab(ParameterType type, String label, bool isDark) {
    final isSelected = _selectedParam == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedParam = type;
        });
        _loadData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryDeepOcean
              : (isDark ? AppColors.darkCardBackground : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryDeepOcean
                : (isDark ? AppColors.darkBorder : AppColors.border),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
          ),
        ),
      ),
    );
  }

  Widget _buildDeltaItem(String label, String value, bool isDark, {bool highlight = false}) {
    return Column(
      children: [
        Text(label, style: AppTypography.muted.copyWith(fontSize: 10.5)),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: highlight
                ? AppColors.teal
                : (isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 24, color: AppColors.border);
  }
}
