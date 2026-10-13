import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import 'home_dashboard_screen.dart';
import 'map_screen.dart';
import 'alerts_screen.dart';
import 'community_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  int _previousIndex = 0;
  bool _isOfflineSimulated = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _previousIndex = widget.initialIndex;
  }

  void _onTabChanged(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  void _toggleOffline() {
    setState(() {
      _isOfflineSimulated = !_isOfflineSimulated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeDashboardScreen(
        onNavigateToTab: _onTabChanged,
        isOfflineSimulated: _isOfflineSimulated,
        onToggleOffline: _toggleOffline,
      ),
      const MapScreen(),
      const AlertsScreen(),
      const CommunityScreen(),
      SettingsScreen(
        isOffline: _isOfflineSimulated,
        onToggleOffline: _toggleOffline,
      ),
    ];

    final isForward = _currentIndex >= _previousIndex;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          final inOffset = Tween<Offset>(
            begin: Offset(isForward ? 0.05 : -0.05, 0.0),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: inOffset,
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
    );
  }
}
