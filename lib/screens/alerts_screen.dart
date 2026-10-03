import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../models/alert_item.dart';
import '../providers/app_state_providers.dart';
import '../providers/repository_providers.dart';
import '../widgets/alert_card.dart';
import '../widgets/empty_state.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  String _selectedFilter = 'All'; // 'All' or 'Unread'

  void _showDetailSheet(AlertItem alert) {
    ref.read(alertRepositoryProvider).markAlertAsRead(alert.id);

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
                    Text('Alert Details', style: AppTypography.sectionHeading),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(alert.title, style: AppTypography.cardTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text('${alert.waterSourceName} • ${alert.timeAgo}', style: AppTypography.muted),
                const SizedBox(height: 12),
                Text(alert.description, style: AppTypography.body),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.altLightAquaBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.teal, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.investigationAdvice,
                          style: AppTypography.secondary.copyWith(color: AppColors.teal, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(alertsStreamProvider);
    final unreadCount = ref.watch(unreadAlertsCountProvider).value ?? 0;

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Alerts'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primaryDeepOcean),
              label: const Text(
                'Mark all read',
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
                      content: Text('All alerts marked as read'),
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
            final filteredAlerts = _selectedFilter == 'Unread'
                ? allAlerts.where((a) => !a.isRead).toList()
                : allAlerts;

            final todayAlerts = filteredAlerts.where((a) => a.isToday).toList();
            final earlierAlerts = filteredAlerts.where((a) => !a.isToday).toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Chips & Counts
                  Row(
                    children: [
                      FilterChip(
                        selected: _selectedFilter == 'All',
                        label: Text('All (${allAlerts.length})'),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedFilter == 'All' ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedFilter == 'All' ? Colors.white : AppColors.primaryText,
                        ),
                        selectedColor: AppColors.primaryDeepOcean,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: _selectedFilter == 'All' ? AppColors.primaryDeepOcean : AppColors.border,
                        ),
                        onSelected: (val) {
                          setState(() {
                            _selectedFilter = 'All';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        selected: _selectedFilter == 'Unread',
                        label: Text('Unread ($unreadCount)'),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedFilter == 'Unread' ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedFilter == 'Unread' ? Colors.white : AppColors.primaryText,
                        ),
                        selectedColor: AppColors.primaryDeepOcean,
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: _selectedFilter == 'Unread' ? AppColors.primaryDeepOcean : AppColors.border,
                        ),
                        onSelected: (val) {
                          setState(() {
                            _selectedFilter = 'Unread';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Notification guideline note
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.secondaryText),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Alerts flag indicator deviations for community awareness. Tap to view details.',
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
                      title: _selectedFilter == 'Unread' ? 'No Unread Alerts' : 'No Alerts',
                      message: _selectedFilter == 'Unread'
                          ? "You're all caught up! No unread alerts remaining."
                          : "No unusual measurements detected across your monitored sources.",
                      buttonText: _selectedFilter == 'Unread' ? 'Show All Alerts' : null,
                      onButtonPressed: _selectedFilter == 'Unread'
                          ? () => setState(() => _selectedFilter = 'All')
                          : null,
                    ),
                  ] else ...[
                    // Today Section
                    if (todayAlerts.isNotEmpty) ...[
                      Text('Today', style: AppTypography.sectionHeading.copyWith(fontSize: 16)),
                      const SizedBox(height: 10),
                      ...todayAlerts.map((alert) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: AlertCard(
                            alert: alert,
                            onViewDetails: () => _showDetailSheet(alert),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // Earlier Section
                    if (earlierAlerts.isNotEmpty) ...[
                      Text('Earlier', style: AppTypography.sectionHeading.copyWith(fontSize: 16)),
                      const SizedBox(height: 10),
                      ...earlierAlerts.map((alert) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: AlertCard(
                            alert: alert,
                            onViewDetails: () => _showDetailSheet(alert),
                          ),
                        );
                      }),
                    ],
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
