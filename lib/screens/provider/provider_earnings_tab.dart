import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';

class ProviderEarningsTab extends ConsumerWidget {
  const ProviderEarningsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsStream = ref.watch(providerBookingsProvider);
    final authState = ref.watch(authProvider);
    final provider = authState.currentProvider;

    if (provider == null) {
      return const Center(child: Text('Provider session not found.'));
    }

    return bookingsStream.when(
      data: (bookings) {
        // Filter completed bookings
        final completedJobs = bookings.where((b) => b.status == 'completed').toList();

        // Calculate current week pending earnings (completed bookings)
        double calculatedPending = 0.0;
        for (var job in completedJobs) {
          final double total = job.pricingBreakdown['total']?.toDouble() ?? 0.0;
          final double platformFee = job.pricingBreakdown['platformFee']?.toDouble() ?? 30.0;
          calculatedPending += (total - platformFee);
        }

        // Historic mock weeks list
        final historicWeeks = [
          {'week': '08 May - 14 May', 'jobs': 12, 'net': 5800.0, 'status': 'Paid ✅'},
          {'week': '01 May - 07 May', 'jobs': 9, 'net': 4100.0, 'status': 'Paid ✅'},
          {'week': '24 Apr - 30 Apr', 'jobs': 15, 'net': 7200.0, 'status': 'Paid ✅'},
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Current Week Earnings Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gold.withOpacity(0.2), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'IS HAFTE KI EARNINGS (PENDING)',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PKR ${calculatedPending.toStringAsFixed(0)}',
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completed Jobs: ${completedJobs.length} matches this week',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. Somwar Payout Warning Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Weekly payments har Somwar (Monday) ko aapke bank/wallet account mein transfer hote hain.',
                        style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 3. Today's Completed Jobs Breakdown
              const Text(
                'Jobs Breakdown',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),

              if (completedJobs.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Is hafte abhi tak koi completed job nahi hai.',
                      style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: completedJobs.length,
                  itemBuilder: (context, index) {
                    final job = completedJobs[index];
                    final double total = job.pricingBreakdown['total']?.toDouble() ?? 0.0;
                    final double platformFee = job.pricingBreakdown['platformFee']?.toDouble() ?? 30.0;
                    final double net = total - platformFee;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(job.service, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                "📍 ${job.customerAreaName} — ${_formatDate(job.createdAt)}",
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'PKR ${net.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Gross: PKR ${total.toStringAsFixed(0)}',
                                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 28),

              // 4. Paid Historic Weeks List
              const Text(
                'Paid Historic Weeks',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: historicWeeks.length,
                itemBuilder: (context, index) {
                  final item = historicWeeks[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['week'] as String, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('${item['jobs']} Jobs Completed', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'PKR ${(item['net'] as double).toStringAsFixed(0)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['status'] as String,
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (err, stack) => Center(child: Text('Earnings load karne mein error: $err')),
    );
  }

  String _formatDate(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year}";
  }
}
