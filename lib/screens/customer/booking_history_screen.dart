import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/local_database.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../models/provider_model.dart';
import '../../providers/provider_provider.dart';
import '../../core/utils/helpers.dart';

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _adminTapCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _onVersionTap() {
    _adminTapCount++;
    if (_adminTapCount >= 3) {
      _adminTapCount = 0;
      context.push(AppRoutes.adminLogin);
    }
  }

  Future<void> _handleRefresh() async {
    // Force refresh stream provider
    ref.invalidate(customerBookingsProvider);
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    final bookingsStream = ref.watch(customerBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      persistentFooterButtons: [
        Center(
          child: GestureDetector(
            onTap: _onVersionTap,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              child: Text(
                'v1.0',
                style: TextStyle(color: Colors.white12, fontSize: 10),
              ),
            ),
          ),
        ),
      ],
      appBar: AppBar(
        title: const Text(
          'Aap Ki Bookings',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: AppColors.gold),
            tooltip: 'Partner Mode Switch',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('⚡ Partner Mode switching triggered...')),
              );
              final success = await ref.read(authProvider.notifier).toggleUserMode();
              if (success) {
                if (context.mounted) {
                  context.go(AppRoutes.providerHome);
                }
              } else {
                if (context.mounted) {
                  final error = ref.read(authProvider).error ?? 'Switching failed';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $error'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.gold,
          unselectedLabelColor: Colors.white30,
          indicatorColor: AppColors.gold,
          tabs: const [
            Tab(text: 'Active ⏳'),
            Tab(text: 'Completed ✅'),
            Tab(text: 'Cancelled ❌'),
          ],
        ),
      ),
      body: bookingsStream.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return _buildEmptyState();
          }

          // Partition bookings
          final active = bookings.where((b) => b.status != 'completed' && b.status != 'cancelled' && b.status != 'provider_cancelled' && b.status != 'disputed').toList();
          final completed = bookings.where((b) => b.status == 'completed' || b.status == 'disputed').toList();
          final cancelled = bookings.where((b) => b.status == 'cancelled' || b.status == 'provider_cancelled').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildRefreshableList(active, 'active'),
              _buildRefreshableList(completed, 'completed'),
              _buildRefreshableList(cancelled, 'cancelled'),
            ],
          );
        },
        loading: () => _buildShimmerList(),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              const Text('Kuch masla aa gaya, dobara try karein', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(customerBookingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshableList(List<BookingModel> list, String type) {
    return RefreshIndicator(
      color: AppColors.gold,
      backgroundColor: AppColors.surface,
      onRefresh: _handleRefresh,
      child: _buildList(list, type),
    );
  }

  Widget _buildList(List<BookingModel> list, String type) {
    if (list.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final booking = list[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final bool isCompleted = booking.status == 'completed';
    final mockProviders = ref.read(mockProvidersProvider);

    // Get provider details
    final provider = mockProviders.firstWhere(
      (p) => p.id == booking.providerId,
      orElse: () => ProviderModel(
        id: booking.providerId,
        name: 'Sajid Expert Plumber',
        phone: '',
        password: '',
        category: booking.service,
        skillLevel: 'expert',
        cnicImageUrl: '',
        approvalStatus: 'approved',
        lat: 25.3960,
        lng: 68.3578,
        areaName: booking.customerAreaName,
        rating: 4.8,
        reviewCount: 20,
        onTimeScore: 0.95,
        cancellationRate: 0.05,
        riskScore: 0.0,
        badges: const [],
        negativeTags: const [],
        shifts: const [],
        baseRatePkr: 500,
        pkrPerKm: 60,
        urgentSurcharge: 100,
        weeklyEarningsPending: 0.0,
        isOnline: true,
        currentLat: 25.3960,
        currentLng: 68.3578,
        createdAt: DateTime.now(),
      ),
    );

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with category icon & status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.12), shape: BoxShape.circle),
                      child: Icon(_getIconForService(booking.service), color: AppColors.gold, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.service, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(provider.name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                _buildStatusBadge(booking.status),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),

            // Date & Total Amount paid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DATE & TIME', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(booking.scheduledAt),
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('PAID AMOUNT', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    const SizedBox(height: 4),
                    Text(
                      'PKR ${booking.pricingBreakdown['total']?.toStringAsFixed(0) ?? '0'}',
                      style: TextStyle(color: AppColors.gold, fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ],
            ),

            // Buttons: Dobara Book / Report Problem
            if (isCompleted || booking.status == 'disputed') ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 42),
                  backgroundColor: const Color(0xff121224),
                  foregroundColor: AppColors.gold,
                  elevation: 0,
                  side: const BorderSide(color: AppColors.gold, width: 1.0),
                ),
                onPressed: () {
                  context.push(AppRoutes.agentLogs, extra: booking.bookingId);
                },
                icon: const Icon(Icons.smart_toy_outlined, size: 16),
                label: const Text('🤖 Agent Logs Dekhein', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        foregroundColor: Colors.redAccent,
                      ),
                      onPressed: () {
                        // Open Slide-up Dispute Sheet!
                        _showDisputeSheet(booking);
                      },
                      child: const Text('Problem Report Karo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                      onPressed: () {
                        // Re-book pre-fills home screen with same category
                        context.go(AppRoutes.customerHome);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('⚡ Dobara Booking in progress for ${booking.service}!'),
                            backgroundColor: AppColors.gold,
                          ),
                        );
                      },
                      child: const Text('Dobara Book Karo'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconForService(String service) {
    switch (service) {
      case 'AC Technician':
        return Icons.ac_unit;
      case 'Plumber':
        return Icons.water_drop;
      case 'Electrician':
        return Icons.bolt;
      case 'Carpenter':
        return Icons.handyman;
      case 'Mechanic':
        return Icons.build;
      default:
        return Icons.design_services;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.green;
    String label = status.toUpperCase();

    if (status == 'booked' || status == 'confirmed') {
      color = AppColors.gold;
    } else if (status == 'cancelled') {
      color = Colors.redAccent;
    } else if (status == 'disputed') {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    return "${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.receipt_long, size: 64, color: Colors.white24),
              const SizedBox(height: 16),
              const Text(
                'Abhi tak koi booking nahi mili.',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Shimmer.fromColors(
            baseColor: Colors.white.withOpacity(0.05),
            highlightColor: Colors.white.withOpacity(0.15),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- DISPUTE FILING SLIDE-UP SHEET ---
  void _showDisputeSheet(BookingModel booking) {
    String selectedDisputeType = 'Overcharged';
    final descriptionController = TextEditingController();
    final claimController = TextEditingController();
    bool isSubmittingDispute = false;
    String? aiResolution;
    bool requiresCustomerConfirmation = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 24,
                left: 20,
                right: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Report a Problem',
                        style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Booking ID: ${booking.bookingId} کے متعلق شکایت درج کروائیں۔',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  if (aiResolution == null) ...[
                    // Dispute Type Dropdown
                    const Text('Masle ki Type (Dispute Type)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDisputeType,
                          dropdownColor: AppColors.surface,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          items: ['No Show', 'Overcharged', 'Poor Quality', 'Provider Cancelled', 'Other'].map((type) {
                            return DropdownMenuItem(value: type, child: Text(type));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                selectedDisputeType = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Problem description textbox
                    const Text('Masla bayan karein (Describe the problem)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        hintText: 'Kam az kam 10 characters likhein...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Amount Claimed (if Overcharged selected)
                    if (selectedDisputeType == 'Overcharged') ...[
                      const Text('Claim Amount (PKR)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: claimController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          hintText: 'Kitne paise overcharge kiye?',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Submit Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: AppColors.secondary),
                      onPressed: isSubmittingDispute ? null : () async {
                        final desc = descriptionController.text.trim();
                        if (desc.length < 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kam az kam 10 characters ki description likhein.'), backgroundColor: AppColors.error),
                          );
                          return;
                        }

                        setSheetState(() {
                          isSubmittingDispute = true;
                        });

                        try {
                            // Local fallback dispute resolution (Agent 9)
                            Helpers.log('History', 'Processing dispute via local Agent 9 resolution');
                            
                            await Future.delayed(const Duration(seconds: 2));

                            final bData = LocalDatabase.instance.get('bookings', booking.bookingId);
                            if (bData != null) {
                              bData['status'] = 'disputed';
                              await LocalDatabase.instance.put('bookings', booking.bookingId, bData);
                            }

                            String resolutionMsg = "Aapka masla samajh aa gaya. Hamara AI system isko assess kar raha hai. Custom claims verification will be completed in 24 hours. Humne provider Hamza AC Tech ki rating review panel par trigger kardi hai. Kia aap replacement booking lagana chahte hain?";
                            
                            // SCENARIO 5: Price Dispute Logic
                            if (selectedDisputeType == 'Overcharged') {
                              final double claimed = double.tryParse(claimController.text) ?? 0.0;
                              final double actualTotal = (booking.pricingBreakdown['total'] as num?)?.toDouble() ?? 0.0;
                              
                              if (claimed > actualTotal * 1.1) {
                                resolutionMsg = "Receipt ke mutabiq aapka total PKR ${actualTotal.toStringAsFixed(0)} tha. Aapka claim PKR ${claimed.toStringAsFixed(0)} hai jo zyada hai. Hum is masle ko note kar rahe hain.";
                              } else {
                                resolutionMsg = "Receipt show karti hai ke sahi amount PKR ${actualTotal.toStringAsFixed(0)} liya gaya. Aapka claim PKR ${claimed.toStringAsFixed(0)} hai.";
                              }
                            }

                            setSheetState(() {
                              aiResolution = resolutionMsg;
                              requiresCustomerConfirmation = true;
                              isSubmittingDispute = false;
                            });
                        } catch (e) {
                          setSheetState(() {
                            isSubmittingDispute = false;
                          });
                        }
                      },
                      child: isSubmittingDispute
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('AI Agent resolving...', style: TextStyle(color: AppColors.primary)),
                              ],
                            )
                          : const Text('Submit Karo'),
                    ),
                  ] else ...[
                    // AI Resolution response UI
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text('AI Agent 9 Resolution', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            aiResolution!,
                            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Customer Yes/No Confirmation Panel
                    if (requiresCustomerConfirmation) ...[
                      const Text(
                        'Kya aap next provider se booking confirm karna chahte hain?',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), foregroundColor: Colors.white70),
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Dispute recorded. Wallet settlement in progress.')),
                                );
                              },
                              child: const Text('Nahi (No)'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                              onPressed: () {
                                Navigator.pop(context);
                                context.go(AppRoutes.customerHome);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Replacement service search triggered!'), backgroundColor: AppColors.gold),
                                );
                              },
                              child: const Text('Haan (Yes)'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: AppColors.secondary),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Done'),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
