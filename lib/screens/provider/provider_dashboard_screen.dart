import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import 'provider_home_tab.dart';
import 'provider_shifts_tab.dart';
import 'provider_earnings_tab.dart';
import 'provider_profile_tab.dart';

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  ConsumerState<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends ConsumerState<ProviderDashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // List of tabs
    final List<Widget> tabs = [
      ProviderHomeTab(
        onNavigateToShifts: () {
          setState(() {
            _currentIndex = 1; // Shifts tab
          });
        },
      ),
      const ProviderShiftsTab(),
      const ProviderEarningsTab(),
      const ProviderProfileTab(),
    ];

    final List<String> titles = [
      'Partner Home',
      'Set Your Shifts',
      'Your Earnings',
      'Partner Profile',
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          titles[_currentIndex],
          style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false, // Don't show back arrow since it is dashboard root
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: tabs,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primary,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: Colors.white30,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.date_range_outlined),
            activeIcon: Icon(Icons.date_range),
            label: 'Shifts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            activeIcon: Icon(Icons.payments),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
