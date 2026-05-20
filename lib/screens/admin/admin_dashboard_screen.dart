import 'package:flutter/material.dart';
import '../../services/local_database.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_approval_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_stats_screen.dart';
import 'admin_announcements_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;

  int _pendingApprovals = 0;
  int _openDisputes = 0;
  int _todayBookings = 0;
  int _activeProviders = 0;
  double _weekRevenue = 0;
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final providers = LocalDatabase.instance.getAll('providers');
      final disputes = LocalDatabase.instance.getAll('disputes');
      final bookings = LocalDatabase.instance.getAll('bookings');
      
      final pendingList = providers.where((p) => p['approvalStatus'] == 'pending').toList();
      final activeList = providers.where((p) => p['approvalStatus'] == 'approved').toList();
      final openList = disputes.where((d) => d['status'] == 'open').toList();
      
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(const Duration(days: 7));
      
      if (!mounted) return;
      
      int todayCount = 0;
      double weekRev = 0;
      for (final data in bookings) {
        final dt = DateTime.tryParse(data['createdAt']?.toString() ?? '');
        if (dt != null) {
          if (dt.isAfter(todayStart)) todayCount++;
          if (dt.isAfter(weekStart)) {
            final pricing = data['pricingBreakdown'] as Map<String, dynamic>? ?? {};
            weekRev += (pricing['total'] ?? 0.0) is num ? (pricing['total'] as num).toDouble() : 0.0;
          }
        }
      }

      setState(() {
        _pendingApprovals = pendingList.length;
        _activeProviders = activeList.length;
        _openDisputes = openList.length;
        _todayBookings = todayCount;
        _weekRevenue = weekRev;
        _statsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      // Mock fallback for demo — instant display
      setState(() {
        _pendingApprovals = 4;
        _activeProviders = 18;
        _openDisputes = 2;
        _todayBookings = 12;
        _weekRevenue = 84500;
        _statsLoaded = true;
      });
    }
  }

  final _titles = ['Admin Home', 'Approvals', 'Disputes', 'Stats', 'Announcements'];

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _buildHome(),
      const AdminApprovalScreen(),
      const AdminDisputesScreen(),
      const AdminStatsScreen(),
      const AdminAnnouncementsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              const Icon(Icons.admin_panel_settings, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text(_titles[_currentIndex], style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go(AppRoutes.splash);
            },
          ),
        ],
      ),
      body: SafeArea(child: IndexedStack(index: _currentIndex, children: tabs)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.primary,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: Colors.white30,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
          BottomNavigationBarItem(
            icon: Badge(label: _pendingApprovals > 0 ? Text('$_pendingApprovals') : null, child: const Icon(Icons.verified_user_outlined)),
            activeIcon: Badge(label: _pendingApprovals > 0 ? Text('$_pendingApprovals') : null, child: const Icon(Icons.verified_user)),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Badge(label: _openDisputes > 0 ? Text('$_openDisputes') : null, child: const Icon(Icons.gavel_outlined)),
            activeIcon: Badge(label: _openDisputes > 0 ? Text('$_openDisputes') : null, child: const Icon(Icons.gavel)),
            label: 'Disputes',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Stats'),
          const BottomNavigationBarItem(icon: Icon(Icons.campaign_outlined), activeIcon: Icon(Icons.campaign), label: 'Announce'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.gold,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Admin greeting
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.surface], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: AppColors.gold, size: 32),
                SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HireIn Admin Terminal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Super Administrator Access', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          const Text('TODAY AT A GLANCE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _statTile('Today Bookings', _statsLoaded ? '$_todayBookings' : '...', Icons.book_online, Colors.blue),
              _statTile('Active Providers', _statsLoaded ? '$_activeProviders' : '...', Icons.people, Colors.green),
              _statTile('Open Disputes', _statsLoaded ? '$_openDisputes' : '...', Icons.gavel, Colors.orange),
              _statTile('Week Revenue', _statsLoaded ? 'PKR ${_weekRevenue.toStringAsFixed(0)}' : '...', Icons.payments, AppColors.gold),
            ],
          ),
          const SizedBox(height: 24),

          // Quick actions
          const Text('QUICK ACTIONS', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 10),
          _quickAction(
            icon: Icons.verified_user,
            label: 'New Provider Approvals',
            badge: _pendingApprovals,
            color: Colors.orange,
            onTap: () => setState(() => _currentIndex = 1),
          ),
          const SizedBox(height: 10),
          _quickAction(
            icon: Icons.gavel,
            label: 'Open Disputes',
            badge: _openDisputes,
            color: Colors.red,
            onTap: () => setState(() => _currentIndex = 2),
          ),
          const SizedBox(height: 10),
          _quickAction(
            icon: Icons.campaign,
            label: 'Send Announcement',
            badge: 0,
            color: AppColors.gold,
            onTap: () => setState(() => _currentIndex = 4),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction({required IconData icon, required String label, required int badge, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Text('$badge', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
          ],
        ),
      ),
    );
  }
}
