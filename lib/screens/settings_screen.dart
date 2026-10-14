import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/config/app_config.dart';
import '../providers/repository_providers.dart';
import '../providers/user_preferences_provider.dart';
import '../providers/app_state_providers.dart';
import '../services/firebase_seed_service.dart';
import 'auth/login_screen.dart';
import 'profile_screen.dart';
import 'info/about_app_screen.dart';
import 'info/help_guide_screen.dart';
import 'info/legal_screen.dart';
import '../features/devices/screens/device_status_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final bool isOffline;
  final VoidCallback? onToggleOffline;

  const SettingsScreen({
    super.key,
    this.isOffline = false,
    this.onToggleOffline,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _versionTapCount = 0;
  DateTime? _lastVersionTapTime;
  bool _isSeeding = false;
  String _seedStatusMessage = '';

  void _handleVersionTap() {
    final now = DateTime.now();
    if (_lastVersionTapTime != null && now.difference(_lastVersionTapTime!).inSeconds > 2) {
      _versionTapCount = 0;
    }
    _lastVersionTapTime = now;
    _versionTapCount++;

    if (_versionTapCount >= 5) {
      _versionTapCount = 0;
      ref.read(userPreferencesProvider.notifier).toggleDemoMode();
      final isDemoNow = ref.read(userPreferencesProvider).isDemoMode;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: isDemoNow ? AppColors.primaryDeepOcean : AppColors.secondaryText,
          duration: const Duration(seconds: 4),
          content: Text(
            isDemoNow
                ? 'Demo Mode Activated! 3 sample sources, 7-day readings & live 10-second ESP32 simulation running.'
                : 'Demo Mode Deactivated. Returned to standard mode.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    } else if (_versionTapCount >= 2) {
      final remaining = 5 - _versionTapCount;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 900),
          content: Text('Tap $remaining more times to toggle Demo Mode.'),
        ),
      );
    }
  }

  Future<void> _handleSeedFirebase() async {
    setState(() {
      _isSeeding = true;
      _seedStatusMessage = 'Connecting to Firebase Firestore...';
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.cloud_upload_rounded, color: AppColors.primaryAqua),
                  SizedBox(width: 10),
                  Text('Seeding Firebase Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  const CircularProgressIndicator(color: AppColors.primaryAqua),
                  const SizedBox(height: 18),
                  Text(
                    _seedStatusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    try {
      await FirebaseSeedService.instance.seedSampleDataToFirebase(
        onProgress: (status) {
          if (mounted) {
            setState(() {
              _seedStatusMessage = status;
            });
          }
        },
      );

      if (mounted) {
        Navigator.pop(context); // Close progress dialog
        setState(() {
          _isSeeding = false;
        });

        // Invalidate all stream providers so the entire app immediately refreshes with new Firestore data!
        ref.invalidate(waterSourcesStreamProvider);
        ref.invalidate(alertsStreamProvider);
        ref.invalidate(unreadAlertsCountProvider);
        ref.invalidate(observationsStreamProvider);
        ref.invalidate(devicesStreamProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.teal,
            duration: Duration(seconds: 4),
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Success! Sample data (sources, readings, alerts & devices) uploaded to Firebase.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        setState(() {
          _isSeeding = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusAttention,
            duration: const Duration(seconds: 5),
            content: Text('Firebase Seeding Error: $e'),
          ),
        );
      }
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of AquaGuard?',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusAttention,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              await ref.read(authRepositoryProvider).signOut();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(userPreferencesProvider);
    final prefsNotifier = ref.read(userPreferencesProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Settings'),
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
              // User Profile Header Box (Tappable to view/edit full profile)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                        isOffline: widget.isOffline,
                        onToggleOffline: widget.onToggleOffline,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: currentUser?.isGuest == true
                            ? AppColors.secondaryText
                            : AppColors.primaryDeepOcean,
                        child: Text(
                          currentUser?.initials ?? 'AG',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.displayName ?? 'AquaGuard User',
                              style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentUser?.isGuest == true
                                  ? 'Guest Observer (Read-only)'
                                  : (currentUser?.email ?? 'user@aquaguard.io'),
                              style: AppTypography.muted.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Demo Mode Active Card (if active)
              if (prefs.isDemoMode) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF134E4A) : const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.teal, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.science_rounded, color: AppColors.teal, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DEMO MODE ACTIVE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.teal,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Using prefix "demo_". Live 10s simulator active.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.teal.shade200 : const Color(0xFF0F766E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: prefs.isDemoMode,
                        activeTrackColor: AppColors.teal,
                        onChanged: (val) => prefsNotifier.toggleDemoMode(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Firebase & Data Management Section
              _sectionHeader('Firebase & Data Management', isDark),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBackground : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAqua.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.cloud_done_rounded, color: AppColors.primaryAqua, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Firebase Backend',
                                style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 14),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                AppConfig.isFirebaseInitialized
                                    ? 'Connected: aquaguard-iot-b8ce2'
                                    : 'Offline Mode / Mock Fallback',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppConfig.isFirebaseInitialized ? AppColors.teal : AppColors.statusWarning,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppConfig.isFirebaseInitialized
                                ? AppColors.teal.withValues(alpha: 0.15)
                                : AppColors.statusWarning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppConfig.isFirebaseInitialized ? 'LIVE' : 'MOCK',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppConfig.isFirebaseInitialized ? AppColors.teal : AppColors.statusWarning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 12),
                    Text(
                      'Populate Cloud Firestore with realistic sample water sources, 7-day diurnal readings, anomaly alerts, and ESP32 telemetry.',
                      style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(fontSize: 11.5, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: const Text('Seed Sample Data to Firebase', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDeepOcean,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSeeding ? null : _handleSeedFirebase,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Appearance & Display Section
              _sectionHeader('Appearance & Display', isDark),
              _switchCard(
                title: 'Dark Theme Mode',
                subtitle: 'High-contrast palette optimized for low-light & field reading',
                value: prefs.isDarkMode,
                isDark: isDark,
                onChanged: (v) => prefsNotifier.setDarkMode(v),
              ),
              const SizedBox(height: 16),

              // Telemetry & Device Sync Section
              _sectionHeader('Telemetry & Network Sync', isDark),
              _switchCard(
                title: 'Sensor Auto-Refresh',
                subtitle: 'Live polling and stream updates for monitored water points',
                value: prefs.sensorAutoRefresh,
                isDark: isDark,
                onChanged: (v) => prefsNotifier.toggleSensorAutoRefresh(),
              ),
              _switchCard(
                title: 'Background Data Sync',
                subtitle: 'Queue observations offline and sync when connected',
                value: prefs.offlineDataSync,
                isDark: isDark,
                onChanged: (v) => prefsNotifier.toggleOfflineSync(),
              ),
              _switchCard(
                title: 'Push Notifications',
                subtitle: 'Instant alerts on unusual water-quality parameter deviations',
                value: prefs.pushNotifications,
                isDark: isDark,
                onChanged: (v) => prefsNotifier.togglePushNotifications(),
              ),
              _switchCard(
                title: 'GPS Location Access',
                subtitle: 'Pinpoint user coordinates when recording field observations',
                value: prefs.gpsLocationAccess,
                isDark: isDark,
                onChanged: (v) => prefsNotifier.toggleGpsLocationAccess(),
              ),
              const SizedBox(height: 16),

              // Unit Preferences Section
              _sectionHeader('Unit Preferences', isDark),
              _optionCard(
                title: 'Temperature Unit',
                value: prefs.temperatureUnit == '°F' ? 'Fahrenheit (°F)' : 'Celsius (°C)',
                isDark: isDark,
                onTap: () {
                  final next = prefs.temperatureUnit == '°C' ? '°F' : '°C';
                  prefsNotifier.setTemperatureUnit(next);
                },
              ),
              _optionCard(
                title: 'TDS / Electrical Conductivity',
                value: prefs.tdsUnit == 'µS/cm' ? 'Conductivity (µS/cm)' : 'Dissolved Solids (ppm)',
                isDark: isDark,
                onTap: () {
                  final next = prefs.tdsUnit == 'ppm' ? 'µS/cm' : 'ppm';
                  prefsNotifier.setTdsUnit(next);
                },
              ),
              _optionCard(
                title: 'Turbidity Unit',
                value: prefs.turbidityUnit == 'JTU' ? 'Jackson Turbidity (JTU)' : 'Nephelometric (NTU)',
                isDark: isDark,
                onTap: () {
                  final next = prefs.turbidityUnit == 'NTU' ? 'JTU' : 'NTU';
                  prefsNotifier.setTurbidityUnit(next);
                },
              ),
              const SizedBox(height: 16),

              // Hardware & Devices Section
              _sectionHeader('Hardware & IoT Devices', isDark),
              _navigationTile(
                icon: Icons.memory_rounded,
                title: 'ESP32 Device Status',
                subtitle: 'Monitor node telemetry, GPS nodes & 10-minute heartbeat',
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DeviceStatusScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // About & Regulatory Section
              _sectionHeader('About & Project Information', isDark),
              _navigationTile(
                icon: Icons.info_outline_rounded,
                title: 'About AquaGuard',
                subtitle: 'Project description & overview of monitored indicators',
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutAppScreen()),
                  );
                },
              ),
              _navigationTile(
                icon: Icons.menu_book_rounded,
                title: 'Indicator Guide & Help',
                subtitle: 'Detailed explanation of pH, TDS, turbidity & temperature bands',
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpGuideScreen()),
                  );
                },
              ),
              _navigationTile(
                icon: Icons.gavel_rounded,
                title: 'Regulatory & Limitations Notice',
                subtitle: 'Official non-potability and environmental baseline statement',
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LegalScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Account & Sign Out Section
              _sectionHeader('Account Session', isDark),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.statusAttention.withValues(alpha: 0.3),
                  ),
                ),
                child: Material(
                  color: isDark ? AppColors.darkCardBackground : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded, color: AppColors.statusAttention),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.statusAttention,
                      ),
                    ),
                    subtitle: Text(
                      currentUser?.isGuest == true
                          ? 'End guest session and return to login'
                          : 'Sign out of current account',
                      style: AppTypography.muted.copyWith(fontSize: 11.5),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.statusAttention),
                    onTap: () => _showSignOutDialog(context),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Version number with hidden 5-tap Demo Mode toggle!
              Center(
                child: GestureDetector(
                  onTap: _handleVersionTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardSubtleBg : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${AppConfig.appName} v${AppConfig.appVersion} (Build ${AppConfig.appBuild})',
                          style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prefs.isDemoMode ? '• Demo Mode Active •' : 'Tap 5x for Demo Mode',
                          style: TextStyle(
                            fontSize: 10,
                            color: prefs.isDemoMode ? AppColors.teal : AppColors.mutedText,
                            fontWeight: prefs.isDemoMode ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 105),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: (isDark ? AppTypography.darkSectionHeading : AppTypography.sectionHeading).copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _switchCard({
    required String title,
    required String subtitle,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Material(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          title: Text(
            title,
            style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 14),
          ),
          subtitle: Text(subtitle, style: AppTypography.muted.copyWith(fontSize: 11.5)),
          value: value,
          activeTrackColor: AppColors.primaryAqua,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _optionCard({
    required String title,
    required String value,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Material(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          title: Text(
            title,
            style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 14),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: AppTypography.secondary.copyWith(
                  color: AppColors.primaryAqua,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.secondaryText),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Material(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon, color: AppColors.primaryAqua, size: 22),
          title: Text(
            title,
            style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 14),
          ),
          subtitle: Text(subtitle, style: AppTypography.muted.copyWith(fontSize: 11.5)),
          trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.secondaryText),
          onTap: onTap,
        ),
      ),
    );
  }
}
