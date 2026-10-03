import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../providers/repository_providers.dart';
import '../providers/user_preferences_provider.dart';
import 'auth/login_screen.dart';
import 'info/legal_screen.dart';

class SettingsScreen extends ConsumerWidget {
  final bool isOffline;
  final VoidCallback? onToggleOffline;

  const SettingsScreen({
    super.key,
    this.isOffline = false,
    this.onToggleOffline,
  });

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your AquaGuard account?',
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
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPreferencesProvider);
    final prefsNotifier = ref.read(userPreferencesProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.primaryText,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prototype Demo Controls Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.altLightAquaBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: AppColors.teal, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Prototype Demonstration Controls',
                          style: AppTypography.cardTitle.copyWith(fontSize: 14, color: AppColors.teal),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toggle offline presentation mode to demonstrate UI handling for remote water sites without cellular signal.',
                      style: AppTypography.muted.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Simulate Offline Mode Banner', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Shows warning banner & queued sync entries', style: TextStyle(fontSize: 11)),
                      value: prefs.isOfflineSimulated,
                      activeThumbColor: AppColors.primaryAqua,
                      onChanged: (val) {
                        prefsNotifier.toggleOfflineSimulation();
                        onToggleOffline?.call();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // General App Preferences Section
              _sectionHeader('Device & Sensor Sync'),
              _switchCard(
                title: 'Offline Data Sync',
                subtitle: 'Automatically cache local readings until network connects',
                value: prefs.offlineDataSync,
                onChanged: (v) => prefsNotifier.updatePreferences(prefs.copyWith(offlineDataSync: v)),
              ),
              _switchCard(
                title: 'Sensor Auto Refresh',
                subtitle: 'Poll connected Bluetooth/Zigbee nodes every 5 minutes',
                value: prefs.sensorAutoRefresh,
                onChanged: (v) => prefsNotifier.updatePreferences(prefs.copyWith(sensorAutoRefresh: v)),
              ),
              _switchCard(
                title: 'GPS Location Access',
                subtitle: 'Tag field measurements with pinpoint coordinates',
                value: prefs.gpsLocationAccess,
                onChanged: (v) => prefsNotifier.updatePreferences(prefs.copyWith(gpsLocationAccess: v)),
              ),
              const SizedBox(height: 16),

              _sectionHeader('Notifications & Alerts'),
              _switchCard(
                title: 'Push Notifications',
                subtitle: 'Receive alerts when water indicators deviate from baseline',
                value: prefs.pushNotifications,
                onChanged: (v) => prefsNotifier.updatePreferences(prefs.copyWith(pushNotifications: v)),
              ),
              const SizedBox(height: 16),

              _sectionHeader('Display Preferences'),
              _optionCard(
                title: 'Temperature Unit',
                value: prefs.temperatureUnit == '°F' ? 'Fahrenheit (°F)' : 'Celsius (°C)',
                onTap: () {
                  final nextUnit = prefs.temperatureUnit == '°C' ? '°F' : '°C';
                  prefsNotifier.setTemperatureUnit(nextUnit);
                },
              ),
              _optionCard(
                title: 'Map View Preference',
                value: prefs.mapStyle,
                onTap: () {
                  final nextStyle = prefs.mapStyle.startsWith('E')
                      ? 'Satellite Hybrid'
                      : 'Environmental Terrain';
                  prefsNotifier.updatePreferences(prefs.copyWith(mapStyle: nextStyle));
                },
              ),
              const SizedBox(height: 16),

              _sectionHeader('Privacy & Data Governance'),
              _simpleTile(
                title: 'Community Data Sharing',
                subtitle: 'Contribute anonymized sensor readings to civic ledger',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LegalScreen(
                        title: 'Community Data Sharing',
                        isPrivacyPolicy: true,
                      ),
                    ),
                  );
                },
              ),
              _simpleTile(
                title: 'Terms of Observation',
                subtitle: 'Community water monitoring terms and safety guidelines',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LegalScreen(
                        title: 'Terms of Observation',
                        isPrivacyPolicy: false,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              _sectionHeader('Account Session'),
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.statusAttention.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.statusAttention),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusAttention,
                    ),
                  ),
                  subtitle: const Text(
                    'Disconnect session and return to sign in',
                    style: TextStyle(fontSize: 11.5, color: AppColors.secondaryText),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.statusAttention),
                  onTap: () => _showSignOutDialog(context, ref),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: AppTypography.sectionHeading.copyWith(fontSize: 15, fontWeight: FontWeight.w700)),
    );
  }

  Widget _switchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: SwitchListTile(
        title: Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
        subtitle: Text(subtitle, style: AppTypography.muted.copyWith(fontSize: 11.5)),
        value: value,
        activeThumbColor: AppColors.primaryAqua,
        onChanged: onChanged,
      ),
    );
  }

  Widget _optionCard({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: AppTypography.secondary.copyWith(color: AppColors.primaryAqua, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _simpleTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        title: Text(title, style: AppTypography.cardTitle.copyWith(fontSize: 14)),
        subtitle: Text(subtitle, style: AppTypography.muted.copyWith(fontSize: 11.5)),
        trailing: const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.secondaryText),
        onTap: onTap,
      ),
    );
  }
}
