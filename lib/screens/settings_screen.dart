import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_typography.dart';
import '../core/config/app_config.dart';
import '../providers/repository_providers.dart';
import '../providers/user_preferences_provider.dart';
import '../providers/app_state_providers.dart';
import 'auth/login_screen.dart';
import 'info/about_app_screen.dart';
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
              // User Profile Header Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBackground : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
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
                    if (currentUser?.isGuest == true)
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        },
                        child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                  ],
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
                subtitle: 'Project description & official regulatory limitations statement',
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutAppScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Appearance & Display Section
              _sectionHeader('Appearance', isDark),
              _switchCard(
                title: 'Dark Theme Mode',
                subtitle: 'High-contrast palette optimized for dark environments',
                value: prefs.isDarkMode,
                isDark: isDark,
                onChanged: (v) => prefsNotifier.toggleDarkMode(),
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
