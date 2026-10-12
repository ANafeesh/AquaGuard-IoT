import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/widgets/disclaimer_banner.dart';
import '../core/widgets/offline_banner.dart';
import '../models/water_source.dart';
import '../models/measurement.dart';
import '../providers/app_state_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/user_preferences_provider.dart';
import '../widgets/measurement_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/alert_card.dart';
import '../widgets/quick_action_card.dart';
import 'water_source_details_screen.dart';
import 'report_measurement_screen.dart';
import 'history_screen.dart';
import '../features/history/widgets/fl_parameter_chart.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;
  final bool isOfflineSimulated;
  final VoidCallback? onToggleOffline;

  const HomeDashboardScreen({
    super.key,
    this.onNavigateToTab,
    this.isOfflineSimulated = false,
    this.onToggleOffline,
  });

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  String _chartRange = '24h';
  Map<String, List<HistoricalPoint>> _phTrends = const {};

  @override
  void initState() {
    super.initState();
    _loadHistoricalTrends();
  }

  Future<void> _loadHistoricalTrends() async {
    final readingRepo = ref.read(readingRepositoryProvider);
    final activeSource = ref.read(activeWaterSourceProvider);
    final sourceId = activeSource?.id ?? 'ws-1';
    final trends = await readingRepo.getHistoricalTrends(sourceId, ParameterType.ph);
    if (mounted) {
      setState(() {
        _phTrends = trends;
      });
    }
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(waterSourcesStreamProvider);
    ref.invalidate(alertsStreamProvider);
    ref.invalidate(unreadAlertsCountProvider);
    ref.invalidate(observationsStreamProvider);
    await _loadHistoricalTrends();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sourcesAsync = ref.watch(waterSourcesStreamProvider);
    final activeSource = ref.watch(activeWaterSourceProvider);
    final unreadAlertsAsync = ref.watch(unreadAlertsCountProvider);
    final weeklyReadingsCount = ref.watch(weeklyReadingsCountProvider);
    final alertsAsync = ref.watch(alertsStreamProvider);
    final userAsync = ref.watch(currentUserProvider);
    final prefs = ref.watch(userPreferencesProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      body: SafeArea(
        child: sourcesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAqua),
          ),
          error: (err, _) => Center(
            child: Text('Error loading dashboard: $err'),
          ),
          data: (allSources) {
            final currentSource = activeSource ?? (allSources.isNotEmpty ? allSources.first : null);
            final readingsAsync = currentSource != null
                ? ref.watch(latestReadingsProvider(currentSource.id))
                : const AsyncValue.data(<ParameterReading>[]);
            final unreadCount = unreadAlertsAsync.value ?? 0;
            final firstAlert = alertsAsync.value?.isNotEmpty == true
                ? alertsAsync.value!.first
                : null;
            final user = userAsync.value;

            return RefreshIndicator(
              color: AppColors.primaryAqua,
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Offline Banner
                    if (widget.isOfflineSimulated || prefs.isOfflineSimulated)
                      OfflineBanner(
                        pendingSyncCount: 2,
                        onDismiss: widget.onToggleOffline,
                      ),

                    // Demo Mode Badge
                    if (prefs.isDemoMode)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
                          border: const Border(
                            bottom: BorderSide(color: AppColors.teal, width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.science_rounded, size: 16, color: AppColors.teal),
                            const SizedBox(width: 8),
                            Text(
                              'DEMO MODE ACTIVE: Live ESP32 simulation running every 10s',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.teal.shade200 : const Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Header Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user != null ? 'Welcome, ${user.displayName}' : 'AquaGuard',
                                  style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Water Quality Dashboard',
                                  style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading).copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Avatar
                          GestureDetector(
                            onTap: () => widget.onNavigateToTab?.call(4),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primaryDeepOcean,
                              child: Text(
                                user?.initials ?? 'AG',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Prominent Regulatory Non-potable Notice
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: DisclaimerBanner(),
                    ),
                    const SizedBox(height: 12),

                    // Quick Summary Metrics Row (Sources, Unread Alerts, Community Readings this week)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          // Monitored Sources Card
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'Sources',
                              value: allSources.length.toString(),
                              subtitle: 'Monitored',
                              icon: Icons.water_drop_rounded,
                              color: AppColors.primaryAqua,
                              isDark: isDark,
                              onTap: () => widget.onNavigateToTab?.call(1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Unacknowledged Alerts Card
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'Alerts',
                              value: unreadCount.toString(),
                              subtitle: unreadCount == 0 ? 'No deviations' : 'Unacknowledged',
                              icon: Icons.notification_important_rounded,
                              color: unreadCount > 0 ? AppColors.statusWarning : AppColors.teal,
                              isDark: isDark,
                              onTap: () => widget.onNavigateToTab?.call(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Community Readings this week Card
                          Expanded(
                            child: _buildSummaryCard(
                              title: 'Community',
                              value: weeklyReadingsCount.toString(),
                              subtitle: 'This week',
                              icon: Icons.people_alt_rounded,
                              color: AppColors.primaryDeepOcean,
                              isDark: isDark,
                              onTap: () => widget.onNavigateToTab?.call(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SUMMARY CARDS FOR THE LATEST READING FROM EACH MONITORED SOURCE
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monitored Water Sources',
                            style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading).copyWith(fontSize: 17),
                          ),
                          Text(
                            '${allSources.length} Active',
                            style: AppTypography.muted.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Horizontal scrolling list of summary cards for EACH source
                    SizedBox(
                      height: 165,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: allSources.length,
                        itemBuilder: (context, index) {
                          final source = allSources[index];
                          final isSelected = currentSource?.id == source.id;
                          return _buildSourceSummaryCard(context, source, isSelected, isDark);
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Detailed Measurements for currently selected source
                    if (currentSource != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${currentSource.name} Measurements',
                                    style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading).copyWith(fontSize: 17),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Updated ${currentSource.lastUpdated}',
                                    style: AppTypography.muted.copyWith(fontSize: 11.5),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                              label: const Text('View All', style: TextStyle(fontSize: 12.5)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => WaterSourceDetailsScreen(waterSource: currentSource),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 2x2 Grid of Measurement Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: readingsAsync.when(
                          loading: () => const SizedBox(
                            height: 160,
                            child: Center(child: CircularProgressIndicator(color: AppColors.primaryAqua)),
                          ),
                          error: (e, _) => Text('Error loading readings: $e'),
                          data: (readings) {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.05,
                              ),
                              itemCount: readings.length,
                              itemBuilder: (context, index) {
                                final reading = readings[index];
                                return MeasurementCard(
                                  reading: reading,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => WaterSourceDetailsScreen(waterSource: currentSource),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Historical fl_chart Trend Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: FlParameterChart(
                        title: 'pH Indicator Trend',
                        parameterName: 'pH',
                        unit: '',
                        points: _phTrends[_chartRange.toUpperCase()] ?? _phTrends['24H'] ?? [],
                        selectedRange: _chartRange,
                        onRangeChanged: (range) {
                          setState(() {
                            _chartRange = range;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Recent Alert Section
                    if (firstAlert != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Anomaly Alert',
                                  style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading).copyWith(fontSize: 16),
                                ),
                                TextButton(
                                  onPressed: () => widget.onNavigateToTab?.call(2),
                                  child: const Text('All Alerts', style: TextStyle(fontSize: 12.5)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            AlertCard(
                              alert: firstAlert,
                              onViewDetails: () => widget.onNavigateToTab?.call(2),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Quick Actions Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Quick Actions',
                        style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading).copyWith(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.map_outlined,
                              label: 'View Map',
                              customColor: AppColors.primaryDeepOcean,
                              onTap: () => widget.onNavigateToTab?.call(1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.add_circle_outline_rounded,
                              label: 'Add Reading',
                              customColor: AppColors.teal,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ReportMeasurementScreen()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.show_chart_rounded,
                              label: 'Graphs',
                              customColor: AppColors.primaryAqua,
                              onTap: () {
                                if (currentSource != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HistoryScreen(initialSource: currentSource),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: QuickActionCard(
                              icon: Icons.people_outline_rounded,
                              label: 'Community',
                              customColor: const Color(0xFF0284C7),
                              onTap: () => widget.onNavigateToTab?.call(3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                  title,
                  style: AppTypography.muted.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                Icon(icon, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceSummaryCard(
    BuildContext context,
    WaterSource source,
    bool isSelected,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedSourceIdProvider.notifier).setSourceId(source.id);
        _loadHistoricalTrends();
      },
      child: Container(
        width: 230,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBackground : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryAqua
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDeepOcean,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: StatusBadge(status: source.status, isCompact: true),
                ),
              ],
            ),
            Text(
              source.name,
              style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Metric readings row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardSubtleBg : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _sourceMetric('pH', source.ph?.toStringAsFixed(1) ?? '--'),
                  _sourceMetric('TDS', '${source.tds}'),
                  _sourceMetric('Turb', source.turbidity?.toStringAsFixed(1) ?? '--'),
                  _sourceMetric('Temp', '${source.temperature?.toStringAsFixed(0) ?? "--"}°C'),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    source.lastUpdated,
                    style: AppTypography.muted.copyWith(fontSize: 10.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WaterSourceDetailsScreen(waterSource: source),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryAqua,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.primaryAqua),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.mutedText)),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
