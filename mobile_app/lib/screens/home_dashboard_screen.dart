import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/water_source.dart';
import '../models/measurement.dart';
import '../providers/app_state_providers.dart';
import '../providers/repository_providers.dart';
import '../widgets/measurement_card.dart';
import '../widgets/custom_chart.dart';
import '../widgets/alert_card.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/offline_banner.dart';
import 'water_source_details_screen.dart';
import 'alerts_screen.dart';
import 'report_measurement_screen.dart';

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

  void _showWaterSourcePicker(List<WaterSource> allSources, WaterSource currentSource) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Water Source',
                      style: AppTypography.sectionHeading,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...allSources.map((source) {
                  final isSelected = source.id == currentSource.id;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryAqua.withValues(alpha: 0.15)
                            : AppColors.mainBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: isSelected
                            ? AppColors.primaryAqua
                            : AppColors.secondaryText,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      source.name,
                      style: AppTypography.cardTitle.copyWith(
                        color: isSelected
                            ? AppColors.primaryDeepOcean
                            : AppColors.primaryText,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${source.coordinates} • ${source.status.label}',
                      style: AppTypography.muted,
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.primaryAqua)
                        : null,
                    onTap: () {
                      ref.read(selectedSourceIdProvider.notifier).setSourceId(source.id);
                      _loadHistoricalTrends();
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
    final activeSource = ref.watch(activeWaterSourceProvider);
    final unreadAlertsAsync = ref.watch(unreadAlertsCountProvider);
    final alertsAsync = ref.watch(alertsStreamProvider);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      body: SafeArea(
        child: sourcesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAqua),
          ),
          error: (err, _) => Center(
            child: Text('Error loading dashboard: $err'),
          ),
          data: (allSources) {
            final currentSource = activeSource ?? allSources.first;
            final readingsAsync = ref.watch(latestReadingsProvider(currentSource.id));
            final unreadCount = unreadAlertsAsync.value ?? 0;
            final firstAlert = alertsAsync.value?.isNotEmpty == true
                ? alertsAsync.value!.first
                : null;
            final user = userAsync.value;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Offline Banner (if simulated offline)
                  if (widget.isOfflineSimulated)
                    OfflineBanner(
                      pendingSyncCount: 4,
                      onDismiss: widget.onToggleOffline,
                    ),

                  // Header Section
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good Morning,',
                              style: AppTypography.secondary.copyWith(
                                color: AppColors.secondaryText,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'AquaGuard Monitoring',
                              style: AppTypography.sectionHeading.copyWith(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        // Notification Bell + Avatar
                        Row(
                          children: [
                            // Bell with alert badge
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AlertsScreen(),
                                  ),
                                );
                              },
                              icon: Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_outlined,
                                      color: AppColors.primaryDeepOcean,
                                      size: 20,
                                    ),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.statusAttention,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Profile avatar
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
                      ],
                    ),
                  ),

                  // Prototype Disclaimer Tag - strictly shown when AppConfig.useMockData is true
                  if (AppConfig.useMockData)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.altLightAquaBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.teal.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.science_outlined,
                              size: 14,
                              color: AppColors.teal,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'UI/UX Prototype Mode • Simulated Data Active',
                                style: AppTypography.muted.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),

                  // Prominent Monitoring Status Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: InkWell(
                      onTap: () => _showWaterSourcePicker(allSources, currentSource),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFE0F2FE), Color(0xFFF0FDFA)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primaryAqua.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryAqua.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Monitoring Status row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.statusNormal
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: AppColors.statusNormal,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'MONITORING ACTIVE',
                                        style: AppTypography.statusBadge.copyWith(
                                          color: AppColors.statusNormal,
                                          fontSize: 11,
                                          letterSpacing: 0.6,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Change',
                                      style: AppTypography.secondary.copyWith(
                                        color: AppColors.primaryAqua,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_drop_down_rounded,
                                      color: AppColors.primaryAqua,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            Text(
                              'Water Source',
                              style: AppTypography.secondary.copyWith(
                                fontSize: 12,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  currentSource.name,
                                  style: AppTypography.largeTitle.copyWith(
                                    fontSize: 24,
                                    color: AppColors.primaryDeepOcean,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.primaryDeepOcean,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 13,
                                  color: AppColors.secondaryText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  currentSource.lastUpdated,
                                  style: AppTypography.muted.copyWith(
                                    color: AppColors.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text('•',
                                    style: TextStyle(color: AppColors.secondaryText)),
                                const SizedBox(width: 10),
                                Text(
                                  currentSource.coordinates,
                                  style: AppTypography.muted.copyWith(
                                    color: AppColors.secondaryText,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Measurements Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Measurements',
                          style: AppTypography.sectionHeading,
                        ),
                        Text(
                          'Sensors Online',
                          style: AppTypography.secondary.copyWith(
                            color: AppColors.primaryAqua,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
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
                        height: 180,
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primaryAqua),
                        ),
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
                                    builder: (context) => WaterSourceDetailsScreen(
                                      waterSource: currentSource,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Water Quality Overview Chart Section
                  if (_phTrends.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: CustomChartCard(
                        title: 'pH Trend',
                        subtitle: 'Stable over the selected period (Mock Data)',
                        dataByRange: _phTrends,
                        unit: '',
                        normalMin: 6.5,
                        normalMax: 8.5,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Recent Alert Section
                  if (firstAlert != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Alert',
                            style: AppTypography.sectionHeading,
                          ),
                          const SizedBox(height: 10),
                          AlertCard(
                            alert: firstAlert,
                            onViewDetails: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AlertsScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Quick Actions Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Quick Actions',
                      style: AppTypography.sectionHeading,
                    ),
                  ),
                  const SizedBox(height: 12),

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
                            icon: Icons.show_chart_rounded,
                            label: 'View History',
                            customColor: AppColors.primaryAqua,
                            onTap: () => widget.onNavigateToTab?.call(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: QuickActionCard(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Report Entry',
                            customColor: AppColors.teal,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ReportMeasurementScreen(),
                                ),
                              );
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
            );
          },
        ),
      ),
    );
  }
}
