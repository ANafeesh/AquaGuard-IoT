import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/widgets/disclaimer_banner.dart';
import '../../../models/home_tank.dart';
import '../../../models/tank_reading.dart';
import '../../../models/water_source.dart';
import '../../../models/measurement.dart';
import '../../../models/community_observation.dart';
import '../../../providers/app_state_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_preferences_provider.dart';
import '../../../widgets/measurement_card.dart';
import '../../../widgets/status_badge.dart';
import '../../history/widgets/fl_parameter_chart.dart';
import '../providers/home_tank_providers.dart';
import 'register_tank_screen.dart';

class PrivateTankDashboardScreen extends ConsumerStatefulWidget {
  final String tankId;

  const PrivateTankDashboardScreen({
    super.key,
    required this.tankId,
  });

  @override
  ConsumerState<PrivateTankDashboardScreen> createState() => _PrivateTankDashboardScreenState();
}

class _PrivateTankDashboardScreenState extends ConsumerState<PrivateTankDashboardScreen> {
  String _selectedChartParameter = 'pH';
  String _chartRange = '24h';

  HomeTank? _findTank(List<HomeTank> tanks) {
    try {
      return tanks.firstWhere((t) => t.id == widget.tankId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleDeleteTank(HomeTank tank) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.statusAttention),
            SizedBox(width: 8),
            Text('Delete Home Tank', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${tank.tankName}"? All private historical sensor readings for this tank will be permanently deleted.',
          style: const TextStyle(fontSize: 13, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusAttention,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final repo = ref.read(homeTankRepositoryProvider);
      final prefs = ref.read(userPreferencesProvider);
      try {
        await repo.deleteTank(tank.id, isDemo: prefs.isDemoMode);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Home tank removed successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.statusAttention,
              content: Text('Failed to delete tank: $e'),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleSimulateReading(HomeTank tank) async {
    final repo = ref.read(homeTankRepositoryProvider);
    final prefs = ref.read(userPreferencesProvider);

    final now = DateTime.now();
    final reading = TankReading(
      id: 'tr_${const Uuid().v4().substring(0, 8)}',
      tankId: tank.id,
      ownerUid: tank.ownerUid,
      deviceId: tank.deviceId ?? 'esp32_sim_node',
      ph: 7.2 + ((now.second % 5) - 2) * 0.08,
      tdsEc: 215.0 + ((now.second % 6) - 3) * 6.0,
      turbidity: 1.3 + ((now.second % 4) - 2) * 0.15,
      temperature: 27.0 + ((now.second % 3) - 1) * 0.4,
      timestamp: now,
      source: 'device',
      status: WaterQualityStatus.withinTypicalRange,
      notes: 'Live simulated ESP32 packet for testing.',
    );

    await repo.addTankReading(reading, isDemo: prefs.isDemoMode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Simulated ESP32 reading recorded for private tank.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleVoluntaryCommunityReport(HomeTank tank) async {
    bool hasConsent = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.public_rounded, color: AppColors.primaryDeepOcean),
                SizedBox(width: 8),
                Text('Civic Water Quality Sharing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You can optionally contribute your tank\'s current water quality reading to the public community water ledger.',
                    style: TextStyle(fontSize: 13, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.privacy_tip_rounded, color: AppColors.teal, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Privacy Protection: Your exact home address and private GPS coordinates will NOT be shared. The observation will only state generalized area coordinates.',
                            style: TextStyle(fontSize: 11.5, height: 1.35, color: AppColors.teal),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text(
                      'I explicitly consent to sharing anonymized water quality metrics with the community.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    value: hasConsent,
                    onChanged: (val) {
                      setDialogState(() => hasConsent = val ?? false);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeepOcean,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: hasConsent ? () => Navigator.pop(dialogCtx, true) : null,
                child: const Text('Submit Anonymously'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      final reportRepo = ref.read(reportRepositoryProvider);
      final user = ref.read(currentUserProvider).value;

      final observation = CommunityObservation(
        id: 'obs_${const Uuid().v4().substring(0, 8)}',
        userId: user?.id ?? 'anonymous_resident',
        waterSourceName: 'Residential Catchment (${tank.location.city ?? 'Colombo'})',
        locationArea: tank.location.city ?? 'Colombo District',
        userName: user?.displayName ?? 'Community Contributor',
        userAvatar: user?.initials ?? 'HM',
        timeAgo: 'Just now',
        notes: 'Anonymized civic residential tank observation. pH ${tank.ph?.toStringAsFixed(1) ?? '7.2'}, TDS ${tank.tdsEc?.toInt() ?? 210} ppm.',
        ph: tank.ph,
        tds: tank.tdsEc?.toInt(),
        turbidity: tank.turbidity,
        temperature: tank.temperature,
        status: tank.status,
        timestamp: DateTime.now(),
      );

      await reportRepo.submitObservation(observation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.teal,
            content: Text('Anonymized civic water observation shared successfully!'),
          ),
        );
      }
    }
  }

  List<HistoricalPoint> _buildHistoricalPoints(List<TankReading> readings, String parameter) {
    if (readings.isEmpty) return [];

    final sorted = List<TankReading>.from(readings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Limit to last 20 readings
    final sub = sorted.length > 20 ? sorted.sublist(sorted.length - 20) : sorted;

    return sub.map((r) {
      final label = DateFormat('HH:mm').format(r.timestamp);
      double val = 0.0;
      switch (parameter) {
        case 'pH':
          val = r.ph;
          break;
        case 'TDS':
          val = r.tdsEc;
          break;
        case 'Turbidity':
          val = r.turbidity;
          break;
        case 'Temp':
          val = r.temperature;
          break;
      }
      return HistoricalPoint(label, val);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tanksAsync = ref.watch(userHomeTanksStreamProvider);
    final readingsAsync = ref.watch(tankReadingsStreamProvider(widget.tankId));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Home Tank Dashboard', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          tanksAsync.when(
            data: (tanks) {
              final tank = _findTank(tanks);
              if (tank == null) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  switch (val) {
                    case 'edit':
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (ctx) => RegisterTankScreen(initialTank: tank)),
                      );
                      break;
                    case 'simulate':
                      _handleSimulateReading(tank);
                      break;
                    case 'community':
                      _handleVoluntaryCommunityReport(tank);
                      break;
                    case 'delete':
                      _handleDeleteTank(tank);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Tank Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'simulate',
                    child: Row(
                      children: [
                        Icon(Icons.science_rounded, size: 18, color: AppColors.teal),
                        SizedBox(width: 8),
                        Text('Simulate Sensor Telemetry'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'community',
                    child: Row(
                      children: [
                        Icon(Icons.share_rounded, size: 18, color: AppColors.primaryAqua),
                        SizedBox(width: 8),
                        Text('Contribute Anonymized Report'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.statusAttention),
                        SizedBox(width: 8),
                        Text('Delete Tank', style: TextStyle(color: AppColors.statusAttention)),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (e, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: tanksAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          ),
          error: (e, _) => Center(child: Text('Error loading tank: $e')),
          data: (tanks) {
            final tank = _findTank(tanks);
            if (tank == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.water_damage_rounded, size: 48, color: AppColors.secondaryText),
                      const SizedBox(height: 12),
                      const Text(
                        'Tank Not Found',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'This tank registration may have been removed or belongs to another user.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Return to Tanks'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final readings = readingsAsync.value ?? [];
            final latestReading = readings.isNotEmpty ? readings.first : null;
            final ph = latestReading?.ph ?? tank.ph;
            final tds = latestReading?.tdsEc ?? tank.tdsEc;
            final turb = latestReading?.turbidity ?? tank.turbidity;
            final temp = latestReading?.temperature ?? tank.temperature;
            final status = latestReading?.status ?? tank.status;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prominent Regulatory Notice (Required)
                  const DisclaimerBanner(compact: true),
                  const SizedBox(height: 12),

                  // Header Card: Tank Name, Type, and Private Shield
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBackground : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                tank.tankName,
                                style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle)
                                    .copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_rounded, size: 12, color: Color(0xFFD97706)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Private • Owner Only',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${tank.tankType.displayName}${tank.capacityLiters != null ? ' • ${tank.capacityLiters} L Capacity' : ''}',
                          style: AppTypography.muted.copyWith(fontSize: 12.5),
                        ),
                        if (tank.notes != null && tank.notes!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            tank.notes!,
                            style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary)
                                .copyWith(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Installation Location Card (Confirmed)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBackground : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.pin_drop_rounded, size: 18, color: AppColors.teal),
                            const SizedBox(width: 8),
                            const Text(
                              'Installation Location',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.teal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Confirmed',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tank.location.address,
                          style: (isDark ? AppTypography.darkBody : AppTypography.body)
                              .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Coordinates: ${tank.location.formattedCoordinates}',
                          style: AppTypography.muted.copyWith(fontSize: 11.5),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 12, color: AppColors.secondaryText),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Confidential: Coordinates are private to your account and never rendered on the public map.',
                                style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary)
                                    .copyWith(fontSize: 10.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ESP32 Sensor Hardware Status Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBackground : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.memory_rounded, size: 18, color: AppColors.primaryDeepOcean),
                                const SizedBox(width: 8),
                                const Text(
                                  'Sensor Node Status',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tank.hasDevice
                                    ? AppColors.teal.withValues(alpha: 0.14)
                                    : AppColors.secondaryText.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                tank.hasDevice ? 'Online' : 'No Node Linked',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: tank.hasDevice ? AppColors.teal : AppColors.secondaryText,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (tank.hasDevice) ...[
                          Text(
                            'Device ID: ${tank.deviceId}',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Last Telemetry: ${tank.lastUpdatedFormatted}',
                            style: AppTypography.muted.copyWith(fontSize: 11.5),
                          ),
                        ] else ...[
                          const Text(
                            'No ESP32 hardware device node linked. You can link a node anytime by editing this tank.',
                            style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Water Quality Status Badge Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Quality Telemetry',
                        style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading)
                            .copyWith(fontSize: 16),
                      ),
                      StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 2x2 Grid of Measurement Cards (reusing existing MeasurementCard)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.45,
                    children: [
                      MeasurementCard(
                        reading: ParameterReading.fromType(
                          type: ParameterType.ph,
                          value: ph ?? 7.0,
                          status: ph != null ? null : WaterQualityStatus.noRecentData,
                        ),
                      ),
                      MeasurementCard(
                        reading: ParameterReading.fromType(
                          type: ParameterType.tds,
                          value: tds ?? 200.0,
                          status: tds != null ? null : WaterQualityStatus.noRecentData,
                        ),
                      ),
                      MeasurementCard(
                        reading: ParameterReading.fromType(
                          type: ParameterType.turbidity,
                          value: turb ?? 1.0,
                          status: turb != null ? null : WaterQualityStatus.noRecentData,
                        ),
                      ),
                      MeasurementCard(
                        reading: ParameterReading.fromType(
                          type: ParameterType.temperature,
                          value: temp ?? 25.0,
                          status: temp != null ? null : WaterQualityStatus.noRecentData,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Historical Charts Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Historical Trends',
                        style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading)
                            .copyWith(fontSize: 16),
                      ),
                      // Parameter Selector Chips
                      Row(
                        children: ['pH', 'TDS', 'Turbidity', 'Temp'].map((p) {
                          final isSelected = _selectedChartParameter == p;
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: ChoiceChip(
                              label: Text(p, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                              selected: isSelected,
                              selectedColor: AppColors.teal,
                              labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                              onSelected: (_) => setState(() => _selectedChartParameter = p),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // FlParameterChart integration
                  Builder(
                    builder: (context) {
                      final points = _buildHistoricalPoints(readings, _selectedChartParameter);
                      String unit = '';
                      switch (_selectedChartParameter) {
                        case 'pH':
                          unit = '';
                          break;
                        case 'TDS':
                          unit = 'ppm';
                          break;
                        case 'Turbidity':
                          unit = 'NTU';
                          break;
                        case 'Temp':
                          unit = '°C';
                          break;
                      }

                      return FlParameterChart(
                        title: '$_selectedChartParameter Telemetry Trend',
                        parameterName: _selectedChartParameter,
                        unit: unit,
                        points: points,
                        selectedRange: _chartRange,
                        onRangeChanged: (r) => setState(() => _chartRange = r),
                        primaryColor: AppColors.teal,
                        accentColor: AppColors.primaryDeepOcean,
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.share_rounded, size: 16),
                          label: const Text('Share Anonymously', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _handleVoluntaryCommunityReport(tank),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Edit Tank', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDeepOcean,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (ctx) => RegisterTankScreen(initialTank: tank)),
                            );
                          },
                        ),
                      ),
                    ],
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
}
