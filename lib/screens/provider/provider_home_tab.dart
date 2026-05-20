import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../models/provider_model.dart';

class ProviderHomeTab extends ConsumerWidget {
  final VoidCallback onNavigateToShifts;

  const ProviderHomeTab({super.key, required this.onNavigateToShifts});

  bool _isCurrentlyAvailable(List<Map<String, dynamic>> shifts) {
    final now = DateTime.now();
    final dateKey = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    final todayShift = shifts.firstWhere(
      (s) => s['date'] == dateKey,
      orElse: () => {},
    );

    if (todayShift.isEmpty || todayShift['ranges'] == null) return false;

    final ranges = todayShift['ranges'] as List;
    final double nowMinutes = now.hour * 60.0 + now.minute;

    for (var r in ranges) {
      if (r is Map) {
        final startStr = r['start']?.toString() ?? '';
        final endStr = r['end']?.toString() ?? '';
        final startParts = startStr.split(':');
        final endParts = endStr.split(':');
        if (startParts.length == 2 && endParts.length == 2) {
          final double startMin = double.parse(startParts[0]) * 60 + double.parse(startParts[1]);
          final double endMin = double.parse(endParts[0]) * 60 + double.parse(endParts[1]);
          
          if (nowMinutes >= startMin && nowMinutes <= endMin) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final provider = authState.currentProvider;
    final bookingsStream = ref.watch(providerBookingsProvider);

    if (provider == null) {
      return const Center(child: Text('Provider session not found.'));
    }

    final bool isAvailable = _isCurrentlyAvailable(provider.shifts);

    return bookingsStream.when(
      data: (bookings) {
        // Today's bookings (filter for today's active pending jobs, e.g. booked, confirmed, en_route, arrived, in_progress)
        final todayJobs = bookings.where((b) => b.status != 'cancelled' && b.status != 'completed').toList();

        // Calculate pending weekly earnings
        final completedJobs = bookings.where((b) => b.status == 'completed').toList();
        double calculatedPending = 0.0;
        for (var job in completedJobs) {
          final double total = job.pricingBreakdown['total']?.toDouble() ?? 0.0;
          final double platformFee = job.pricingBreakdown['platformFee']?.toDouble() ?? 30.0;
          calculatedPending += (total - platformFee);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salam, ${provider.name}! 👋',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.category,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.gold.withOpacity(0.12),
                    child: Text(
                      provider.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Shift Status Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isAvailable ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAvailable ? 'Aap Available Hain' : 'Abhi Shift Nahi',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAvailable ? 'Active Shift Ends Today' : 'Add custom range shifts',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (!isAvailable)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold.withOpacity(0.12),
                          foregroundColor: AppColors.gold,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: onNavigateToShifts,
                        child: const Text('Shift Add Karo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. Weekly Earnings Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.surface, AppColors.background],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PENDING WEEKLY EARNINGS',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'PKR ${calculatedPending.toStringAsFixed(0)}',
                      style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w900, fontSize: 24),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 4. Today's Bookings List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's Bookings",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (todayJobs.isNotEmpty)
                    Text(
                      '${todayJobs.length} active jobs',
                      style: const TextStyle(color: AppColors.gold, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (todayJobs.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    child: Column(
                      children: [
                        Icon(Icons.assignment_turned_in_outlined, size: 40, color: Colors.white.withOpacity(0.08)),
                        const SizedBox(height: 12),
                        const Text(
                          'Abhi koi booking nahi hai.',
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayJobs.length,
                  itemBuilder: (context, index) {
                    final job = todayJobs[index];
                    final double total = job.pricingBreakdown['total']?.toDouble() ?? 0.0;
                    final double platformFee = job.pricingBreakdown['platformFee']?.toDouble() ?? 30.0;
                    final double earnings = total - platformFee;

                    return Card(
                      color: AppColors.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        onTap: () {
                          // Route push to ProviderJobDetailsScreen
                          context.push(AppRoutes.providerJobDetails, extra: job.bookingId);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        job.service,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusIndicator(job.status),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "📍 ${job.customerAreaName} — Schedule: ${job.scheduledAt.hour}:${job.scheduledAt.minute.toString().padLeft(2, '0')}",
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'PKR ${earnings.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text('Your Net', style: TextStyle(color: AppColors.textSecondary, fontSize: 9)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),

              // 5. Nayi Shift Add Karo Quick action button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppColors.secondary,
                ),
                onPressed: onNavigateToShifts,
                child: const Text('Nayi Shift Add Karo'),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (err, stack) => Center(child: Text('Bookings load karne mein masla hua: $err')),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color color = Colors.orange;
    if (status == 'confirmed') {
      color = AppColors.gold;
    } else if (status == 'en_route' || status == 'arrived' || status == 'in_progress') {
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 8),
      ),
    );
  }
}
