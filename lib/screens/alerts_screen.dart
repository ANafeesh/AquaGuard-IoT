import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../models/alert_item.dart';
import '../models/water_source.dart';
import '../providers/app_state_providers.dart';
import '../providers/repository_providers.dart';
import '../widgets/empty_state.dart';
import 'history_screen.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  String _selectedFilter = 'All'; // 'All' or 'Unacknowledged'

  void _showDetailSheet(AlertItem alert, List<WaterSource> sources) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final matchedSource = sources.where((s) => s.id == alert.sourceId || s.name == alert.waterSourceName).firstOrNull;

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
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Anomaly Alert Details', style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Alert Title & Source
                Text(
                  'Unusual ${alert.parameter} Measurement',
                  style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${alert.waterSourceName} • Detected ${alert.timeAgo}',
                  style: AppTypography.muted.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 12),

                // Mandatory Neutral Anomaly Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.statusWarningDarkBg : AppColors.statusWarningBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.statusWarning, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          alert.message, // "Unusual water-quality measurement detected at this location."
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.amber.shade200 : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Recorded Indicator Value
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardSubtleBg : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Triggering Parameter Value:',
                        style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(fontSize: 13),
                      ),
                      Text(
                        '${alert.parameter}: ${alert.value != null ? alert.value.toString() : "Shift outside baseline"}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.statusAttention,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Investigation advice
                Text(
                  alert.investigationAdvice,
                  style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 20),

                // Action Buttons: Acknowledge & View Source History
                Row(
                  children: [
                    if (!alert.acknowledged) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text('Acknowledge'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            await ref.read(alertRepositoryProvider).acknowledgeAlert(alert.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Alert acknowledged.')),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.show_chart_rounded, size: 18),
                        label: const Text('View History'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryDeepOcean,
                          side: const BorderSide(color: AppColors.primaryAqua),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          if (matchedSource != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HistoryScreen(initialSource: matchedSource),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HistoryScreen()),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
    final alertsAsync = ref.watch(alertsStreamProvider);
    final sources = ref.watch(waterSourcesStreamProvider).value ?? [];
    final unreadCount = ref.watch(unreadAlertsCountProvider).value ?? 0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Water Quality Alerts'),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primaryDeepOcean),
              label: const Text(
                'Acknowledge All',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDeepOcean,
                ),
              ),
              onPressed: () async {
                await ref.read(alertRepositoryProvider).markAllAsRead();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All alerts marked as acknowledged.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
        ],
      ),
      body: SafeArea(
        child: alertsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primaryAqua),
          ),
          error: (e, _) => Center(child: Text('Error loading alerts: $e')),
          data: (allAlerts) {
            final filteredAlerts = _selectedFilter == 'Unacknowledged'
                ? allAlerts.where((a) => !a.acknowledged && !a.isRead).toList()
                : allAlerts;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips & Counts
                  Row(
                    children: [
                      FilterChip(
                        selected: _selectedFilter == 'All',
                        label: Text('All Alerts (${allAlerts.length})'),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedFilter == 'All' ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedFilter == 'All' ? Colors.white : (isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
                        ),
                        selectedColor: AppColors.primaryDeepOcean,
                        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
                        side: BorderSide(
                          color: _selectedFilter == 'All' ? AppColors.primaryDeepOcean : (isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        onSelected: (val) {
                          setState(() {
                            _selectedFilter = 'All';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedFilter == 'Unacknowledged',
                        label: Text('Unacknowledged ($unreadCount)'),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedFilter == 'Unacknowledged' ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedFilter == 'Unacknowledged' ? Colors.white : (isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
                        ),
                        selectedColor: AppColors.primaryDeepOcean,
                        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
                        side: BorderSide(
                          color: _selectedFilter == 'Unacknowledged' ? AppColors.primaryDeepOcean : (isDark ? AppColors.darkBorder : AppColors.border),
                        ),
                        onSelected: (val) {
                          setState(() {
                            _selectedFilter = 'Unacknowledged';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Guideline note
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBackground : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.secondaryText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Alerts notify you when sensor telemetry deviates >3 std deviations or sudden step changes occur.',
                            style: AppTypography.muted.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (filteredAlerts.isEmpty) ...[
                    const SizedBox(height: 40),
                    EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: _selectedFilter == 'Unacknowledged' ? 'No Unacknowledged Alerts' : 'No Alerts',
                      message: _selectedFilter == 'Unacknowledged'
                          ? "All anomaly alerts have been acknowledged."
                          : "No unusual water-quality measurements detected across monitored sources.",
                      buttonText: _selectedFilter == 'Unacknowledged' ? 'Show All Alerts' : null,
                      onButtonPressed: _selectedFilter == 'Unacknowledged'
                          ? () => setState(() => _selectedFilter = 'All')
                          : null,
                    ),
                  ] else ...[
                    ...filteredAlerts.map((alert) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCardBackground : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !alert.acknowledged
                                ? AppColors.statusWarning.withValues(alpha: 0.5)
                                : (isDark ? AppColors.darkBorder : AppColors.border),
                            width: !alert.acknowledged ? 1.5 : 1.0,
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
                          onTap: () => _showDetailSheet(alert, sources),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.statusWarningDarkBg : AppColors.statusWarningBg,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      size: 18,
                                      color: AppColors.statusWarning,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Unusual ${alert.parameter} reading',
                                                style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              alert.timeAgo,
                                              style: AppTypography.muted.copyWith(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          alert.waterSourceName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryAqua,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Exact message required by prompt: "Unusual water-quality measurement detected at this location."
                              Text(
                                alert.message,
                                style: (isDark ? AppTypography.darkBody : AppTypography.body).copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Parameter, Value, Time row
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCardSubtleBg : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Parameter: ${alert.parameter}',
                                      style: AppTypography.muted.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                    if (alert.value != null)
                                      Text(
                                        'Value: ${alert.value}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.statusWarning,
                                        ),
                                      ),
                                    Text(
                                      alert.isToday ? 'Today' : 'Logged',
                                      style: AppTypography.muted.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Acknowledge Button & Details link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (!alert.acknowledged)
                                    TextButton.icon(
                                      icon: const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.teal),
                                      label: const Text('Acknowledge', style: TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700, fontSize: 12)),
                                      onPressed: () async {
                                        await ref.read(alertRepositoryProvider).acknowledgeAlert(alert.id);
                                      },
                                    )
                                  else
                                    Row(
                                      children: [
                                        const Icon(Icons.check_rounded, size: 14, color: AppColors.mutedText),
                                        const SizedBox(width: 4),
                                        Text('Acknowledged', style: AppTypography.muted.copyWith(fontSize: 11)),
                                      ],
                                    ),
                                  InkWell(
                                    onTap: () => _showDetailSheet(alert, sources),
                                    child: const Row(
                                      children: [
                                        Text('View measurement & history', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryAqua)),
                                        Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.primaryAqua),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
