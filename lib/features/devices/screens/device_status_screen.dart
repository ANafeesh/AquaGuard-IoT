import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../models/device.dart';
import '../../../providers/app_state_providers.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/error_state_view.dart';
import '../../../core/widgets/loading_indicator_view.dart';

class DeviceStatusScreen extends ConsumerWidget {
  const DeviceStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final devicesAsync = ref.watch(devicesStreamProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('ESP32 Device Status'),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
      ),
      body: SafeArea(
        child: devicesAsync.when(
          loading: () => const LoadingIndicatorView(message: 'Querying IoT device telemetry...'),
          error: (err, _) => ErrorStateView(
            title: 'Telemetry Unavailable',
            message: 'Unable to communicate with ESP32 sensor registry: $err',
            onRetry: () => ref.refresh(devicesStreamProvider),
          ),
          data: (devices) {
            if (devices.isEmpty) {
              return EmptyStateView(
                icon: Icons.developer_board_off_rounded,
                title: 'No Registered Devices',
                message: 'No ESP32 sensor hardware nodes found in your deployment registry.',
                buttonText: 'Refresh Devices',
                onButtonPressed: () => ref.refresh(devicesStreamProvider),
              );
            }

            final onlineCount = devices.where((d) => d.isOnline).length;
            final offlineCount = devices.length - onlineCount;

            return RefreshIndicator(
              color: AppColors.primaryAqua,
              onRefresh: () async {
                ref.invalidate(devicesStreamProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Status summary card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: isDark ? AppColors.darkCardGradient : AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDeepOcean.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatusCounter('Total Nodes', devices.length.toString(), Colors.white),
                        Container(width: 1, height: 36, color: Colors.white24),
                        _buildStatusCounter('Online (<10m)', onlineCount.toString(), const Color(0xFF6EE7B7)),
                        Container(width: 1, height: 36, color: Colors.white24),
                        _buildStatusCounter('Offline', offlineCount.toString(), const Color(0xFFFCA5A5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Hardware Sensor Nodes',
                    style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading).copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Devices seen in the last 10 minutes are marked as Online.',
                    style: AppTypography.muted.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 14),

                  ...devices.map((device) => _buildDeviceCard(context, device, isDark)),

                  const SizedBox(height: 20),

                  // Hardware & Specification Notes
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBackground : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.memory_rounded, size: 20, color: AppColors.primaryAqua),
                            const SizedBox(width: 8),
                            Text(
                              'ESP32 Architecture & Sensors',
                              style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Each node features an ESP32 micro-controller with integrated GPS module, '
                          'analog pH probe, TDS/conductivity meter, optical turbidity sensor, and DS18B20 digital '
                          'waterproof temperature probe. Telemetry broadcasts every 10–60 seconds via Wi-Fi/cellular.',
                          style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCounter(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(BuildContext context, Device device, bool isDark) {
    final isOnline = device.isOnline;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnline
              ? AppColors.teal.withValues(alpha: 0.3)
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: 1.2,
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? (isDark ? AppColors.statusNormalDarkBg : AppColors.statusNormalBg)
                            : (isDark ? AppColors.darkCardSubtleBg : AppColors.mainBackground),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.router_rounded,
                        size: 20,
                        color: isOnline ? AppColors.teal : AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${device.id} • ${device.firmwareVersion ?? "v1.0.0"}',
                            style: AppTypography.muted.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline
                      ? (isDark ? AppColors.statusNormalDarkBg : AppColors.statusNormalBg)
                      : (isDark ? AppColors.darkCardSubtleBg : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isOnline ? AppColors.teal.withValues(alpha: 0.4) : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isOnline ? AppColors.teal : AppColors.mutedText,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isOnline
                            ? (isDark ? Colors.teal.shade200 : AppColors.teal)
                            : AppColors.secondaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTelemetryStat(
                Icons.access_time_rounded,
                'Last Seen',
                device.lastSeenFormatted,
                isDark,
              ),
              if (device.batteryLevel != null)
                _buildTelemetryStat(
                  Icons.battery_charging_full_rounded,
                  'Battery',
                  '${device.batteryLevel}%',
                  isDark,
                ),
              if (device.signalStrength != null)
                _buildTelemetryStat(
                  Icons.wifi_rounded,
                  'Signal',
                  '${device.signalStrength} dBm',
                  isDark,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryStat(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondaryText),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: AppTypography.muted.copyWith(fontSize: 11),
        ),
        Text(
          value,
          style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
