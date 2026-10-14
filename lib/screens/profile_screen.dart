import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../providers/app_state_providers.dart';
import '../providers/saved_sources_provider.dart';
import '../providers/repository_providers.dart';
import 'settings_screen.dart';
import 'alerts_screen.dart';
import 'profile/my_observations_screen.dart';
import 'profile/saved_water_sources_screen.dart';
import 'info/help_guide_screen.dart';
import 'info/about_app_screen.dart';

class ProfileScreen extends ConsumerWidget {
  final VoidCallback? onToggleOffline;
  final bool isOffline;

  const ProfileScreen({
    super.key,
    this.onToggleOffline,
    this.isOffline = false,
  });

  void _showEditProfileDialog(BuildContext context, WidgetRef ref, String currentName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Display Name',
          style: isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle,
        ),
        content: TextField(
          controller: controller,
          style: TextStyle(color: isDark ? AppColors.darkPrimaryText : AppColors.primaryText),
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: TextStyle(color: isDark ? AppColors.darkMutedText : AppColors.secondaryText),
            filled: true,
            fillColor: isDark ? AppColors.darkCardSubtleBg : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeepOcean,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await ref.read(authRepositoryProvider).updateDisplayName(newName);
                ref.invalidate(currentUserProvider);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userAsync = ref.watch(currentUserProvider);
    final unreadAlertsAsync = ref.watch(unreadAlertsCountProvider);
    final savedSources = ref.watch(savedWaterSourcesProvider);
    final observationsAsync = ref.watch(observationsStreamProvider);

    final user = userAsync.value;
    final unreadCount = unreadAlertsAsync.value ?? 0;
    final observationsCount = observationsAsync.value?.length ?? 0;
    final savedSourcesCount = savedSources.length;

    final savedSourcesSummary = savedSources.isNotEmpty
        ? savedSources.take(3).map((s) => s.name).join(', ')
        : 'No saved sources yet';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.mainBackground,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: isDark ? AppColors.darkCardBackground : Colors.white,
        elevation: 0,
        foregroundColor: isDark ? AppColors.darkPrimaryText : AppColors.primaryText,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    isOffline: isOffline,
                    onToggleOffline: onToggleOffline,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User Avatar & Name Card (Tappable to edit)
              InkWell(
                onTap: () => _showEditProfileDialog(context, ref, user?.displayName ?? 'AquaGuard User'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: user?.isGuest == true
                                ? AppColors.secondaryText
                                : AppColors.primaryDeepOcean,
                            child: Text(
                              user?.initials ?? 'AG',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryAqua,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user?.displayName ?? 'AquaGuard User',
                        style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.isGuest == true
                            ? 'Guest Observer (Read-only)'
                            : (user?.email ?? 'user@example.com'),
                        style: (isDark ? AppTypography.darkSecondary : AppTypography.secondary).copyWith(
                          color: isDark ? AppColors.darkMutedText : AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.statusNormalDarkBg : AppColors.altLightAquaBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          user?.role ?? 'Community Water Monitor',
                          style: AppTypography.statusBadge.copyWith(
                            color: AppColors.teal,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Activity Metrics Row - dynamically derived from state
              Row(
                children: [
                  Expanded(child: _metricBox('$observationsCount', 'Observations', isDark)),
                  const SizedBox(width: 10),
                  Expanded(child: _metricBox('$savedSourcesCount', 'Monitored Sources', isDark)),
                  const SizedBox(width: 10),
                  Expanded(child: _metricBox('${user?.daysActive ?? 28}', 'Days Active', isDark)),
                ],
              ),
              const SizedBox(height: 24),

              // Menu Sections - all leading to real screens
              _menuItem(
                icon: Icons.assignment_outlined,
                title: 'My Observations',
                subtitle: '$observationsCount recorded field observations',
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyObservationsScreen()),
                  );
                },
              ),
              _menuItem(
                icon: Icons.bookmark_border_rounded,
                title: 'Saved Water Sources',
                subtitle: savedSourcesSummary,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SavedWaterSourcesScreen()),
                  );
                },
              ),
              _menuItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications & Alerts',
                subtitle: 'Alerts for parameter shifts',
                badgeText: unreadCount > 0 ? '$unreadCount New' : null,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AlertsScreen()),
                  );
                },
              ),
              _menuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'App preferences and offline mode toggle',
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        isOffline: isOffline,
                        onToggleOffline: onToggleOffline,
                      ),
                    ),
                  );
                },
              ),
              _menuItem(
                icon: Icons.help_outline_rounded,
                title: 'Help & Information',
                subtitle: 'Understanding indicators (pH, TDS, NTU)',
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpGuideScreen()),
                  );
                },
              ),
              _menuItem(
                icon: Icons.info_outline_rounded,
                title: 'About AquaGuard',
                subtitle: 'Smart Water Quality Monitoring UI/UX Prototype',
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutAppScreen()),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricBox(String val, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(
              fontSize: 18,
              color: AppColors.primaryAqua,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: (isDark ? AppTypography.darkSecondary : AppTypography.muted).copyWith(
              fontSize: 11,
              color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badgeText,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryAqua.withValues(alpha: isDark ? 0.18 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryAqua, size: 20),
        ),
        title: Text(
          title,
          style: (isDark ? AppTypography.darkCardTitle : AppTypography.cardTitle).copyWith(fontSize: 14.5),
        ),
        subtitle: Text(
          subtitle,
          style: AppTypography.muted.copyWith(
            fontSize: 11.5,
            color: isDark ? AppColors.darkMutedText : AppColors.mutedText,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeText != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.statusAttentionDarkBg : AppColors.statusAttentionBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.statusAttention),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText, size: 20),
          ],
        ),
      ),
    );
  }
}
