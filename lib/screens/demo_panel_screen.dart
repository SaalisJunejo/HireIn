import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../utils/demo_helper.dart';
import '../providers/auth_provider.dart';

class DemoPanelScreen extends ConsumerWidget {
  const DemoPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Admin Demo Panel', style: TextStyle(color: AppColors.gold)),
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mock Data Control',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                DemoHelper.seedDemoData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeded 20 Providers!')));
              },
              child: const Text('Seed Demo Data'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                if (user != null) {
                  DemoHelper.simulateFullBooking(user.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulated Full Booking!')));
                }
              },
              child: const Text('Simulate Full Booking'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent), minimumSize: const Size(double.infinity, 50)),
              onPressed: () {
                if (user != null) {
                  DemoHelper.resetDemoState(user.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo State Reset!')));
                }
              },
              child: const Text('Reset Demo State'),
            ),
            const SizedBox(height: 32),
            const Text(
              'Stress Test Scenarios',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildScenarioButton(context, ref, '1. No Provider', 1),
            _buildScenarioButton(context, ref, '2. Ambiguous Input', 2),
            _buildScenarioButton(context, ref, '3. Double Booking Conflict', 3),
            _buildScenarioButton(context, ref, '4. Provider Cancels', 4),
            _buildScenarioButton(context, ref, '5. Price Dispute', 5),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioButton(BuildContext context, WidgetRef ref, String label, int id) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          side: const BorderSide(color: AppColors.gold),
          minimumSize: const Size(double.infinity, 45),
        ),
        onPressed: () {
          DemoHelper.triggerScenario(context, ref, id);
        },
        child: Text(label),
      ),
    );
  }
}
