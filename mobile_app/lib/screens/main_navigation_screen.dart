import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav.dart';
import 'home_dashboard_screen.dart';
import 'map_screen.dart';
import 'history_screen.dart';
import 'community_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  bool _isOfflineSimulated = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabChanged(int index) {
    setState(() {
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
      const HistoryScreen(),
      const CommunityScreen(),
      ProfileScreen(
        isOffline: _isOfflineSimulated,
        onToggleOffline: _toggleOffline,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabChanged,
      ),
    );
  }
}
