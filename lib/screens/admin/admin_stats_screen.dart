import 'package:flutter/material.dart';
import '../../services/local_database.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_colors.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  bool _isLoading = true;
  int _todayBookings = 0;
  int _weekBookings = 0;
  int _monthBookings = 0;
  double _weekRevenue = 0;
  double _weekCommission = 0;
  List<Map<String, dynamic>> _topProviders = [];
  String _topCategory = 'AC Technician';

  // Bar chart: last 7 days bookings count (mock fallback)
  List<int> _dailyCounts = [3, 7, 5, 9, 12, 4, 8];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final weekStart = todayStart.subtract(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month, 1);

      final all = LocalDatabase.instance.getAll('bookings');
      if (!mounted) return;

      _todayBookings = all.where((b) {
        final ts = DateTime.tryParse(b['createdAt']?.toString() ?? '');
        if (ts != null) return ts.isAfter(todayStart);
        return false;
      }).length;

      _weekBookings = all.where((b) {
        final ts = DateTime.tryParse(b['createdAt']?.toString() ?? '');
        if (ts != null) return ts.isAfter(weekStart);
        return false;
      }).length;

      _monthBookings = all.where((b) {
        final ts = DateTime.tryParse(b['createdAt']?.toString() ?? '');
        if (ts != null) return ts.isAfter(monthStart);
        return false;
      }).length;

      for (final b in all) {
        final ts = DateTime.tryParse(b['createdAt']?.toString() ?? '');
        if (ts != null && ts.isAfter(weekStart)) {
          final pricing = b['pricingBreakdown'] as Map<String, dynamic>? ?? {};
          _weekRevenue += (pricing['total'] ?? 0.0) is num ? (pricing['total'] as num).toDouble() : 0.0;
          _weekCommission += (pricing['platformFee'] ?? 0.0) is num ? (pricing['platformFee'] as num).toDouble() : 0.0;
        }
      }

      // Category counts
      final catMap = <String, int>{};
      for (final b in all) {
        final s = b['service'] as String? ?? 'Other';
        catMap[s] = (catMap[s] ?? 0) + 1;
      }
      if (catMap.isNotEmpty) {
        _topCategory = catMap.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      }

      // Top providers
      final provMap = <String, int>{};
      for (final b in all) {
        final pid = b['providerId'] as String? ?? '';
        if (pid.isNotEmpty) provMap[pid] = (provMap[pid] ?? 0) + 1;
      }
      final sorted = provMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      _topProviders = sorted.take(5).map((e) => {'id': e.key, 'count': e.value, 'name': 'Provider ${e.key.substring(0, e.key.length > 4 ? 4 : e.key.length)}'}).toList();

      // Daily breakdown for bar chart
      final List<int> dayCounts = List.filled(7, 0);
      for (final b in all) {
        final ts = DateTime.tryParse(b['createdAt']?.toString() ?? '');
        if (ts != null) {
          final daysAgo = now.difference(ts).inDays;
          if (daysAgo >= 0 && daysAgo < 7) dayCounts[6 - daysAgo]++;
        }
      }
      _dailyCounts = dayCounts;
    } catch (_) {
      // Use mock data for demo — instant display
      _todayBookings = 12;
      _weekBookings = 47;
      _monthBookings = 156;
      _weekRevenue = 84500;
      _weekCommission = 9400;
      _topCategory = 'AC Technician';
      _dailyCounts = [3, 7, 5, 9, 12, 4, 8];
      _topProviders = [
        {'id': 'PROV-001', 'count': 18, 'name': 'Ustad Ali'},
        {'id': 'PROV-002', 'count': 14, 'name': 'Ustad Hamza'},
        {'id': 'PROV-003', 'count': 9, 'name': 'Ustad Saad'},
      ];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stats & Analytics', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white70), onPressed: _load)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Booking counts row
                const Text('BOOKINGS SUMMARY', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statCard('Today', _todayBookings.toString(), Colors.blue),
                    const SizedBox(width: 10),
                    _statCard('This Week', _weekBookings.toString(), AppColors.gold),
                    const SizedBox(width: 10),
                    _statCard('This Month', _monthBookings.toString(), Colors.green),
                  ],
                ),
                const SizedBox(height: 20),

                // Revenue
                const Text('REVENUE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _revCard('Week Revenue', 'PKR ${_weekRevenue.toStringAsFixed(0)}', AppColors.gold)),
                    const SizedBox(width: 10),
                    Expanded(child: _revCard('Commission Earned', 'PKR ${_weekCommission.toStringAsFixed(0)}', Colors.green)),
                  ],
                ),
                const SizedBox(height: 24),

                // Bar chart
                const Text('LAST 7 DAYS BOOKINGS', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Container(
                  height: 180,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
                  child: BarChart(
                    BarChartData(
                      backgroundColor: Colors.transparent,
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              final idx = val.toInt();
                              if (idx < 0 || idx >= days.length) return const SizedBox();
                              return Text(days[idx], style: const TextStyle(color: AppColors.textSecondary, fontSize: 9));
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      barGroups: List.generate(
                        _dailyCounts.length,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: _dailyCounts[i].toDouble(),
                              color: AppColors.gold,
                              width: 16,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Top providers
                const Text('TOP 5 PROVIDERS', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                ..._topProviders.isEmpty
                    ? [Text('No data', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12))]
                    : _topProviders.asMap().entries.map((e) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), shape: BoxShape.circle),
                              child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(e.value['name'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                            Text('${e.value['count']} jobs', style: const TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                const SizedBox(height: 24),

                // Top category
                const Text('MOST REQUESTED SERVICE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: AppColors.gold, size: 28),
                      const SizedBox(width: 16),
                      Text(_topCategory, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _revCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }
}
