import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../services/local_database.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/provider_provider.dart';
import '../../models/booking_model.dart';
import '../../models/provider_model.dart';
import '../../services/firestore_service.dart';
import '../../core/utils/helpers.dart';

class ActiveJobScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const ActiveJobScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ActiveJobScreen> createState() => _ActiveJobScreenState();
}

class _ActiveJobScreenState extends ConsumerState<ActiveJobScreen> {
  GoogleMapController? _mapController;
  Timer? _movementTimer;
  double _providerLat = 25.3850; // Dynamic mock provider starting latitude
  double _providerLng = 68.3450; // Dynamic mock provider starting longitude
  final double _customerLat = 25.3960;
  final double _customerLng = 68.3578;
  
  // Custom Map Dark Style
  static const String _mapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#111122"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#8c8c9e"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#111122"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#202035"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#090911"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _startMockMovement();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Live Provider Tracking updates every 30s
  void _startMockMovement() {
    _movementTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          // Incrementally drift coordinates towards customer coords
          if (_providerLat < _customerLat) {
            _providerLat += 0.0020;
          } else {
            _providerLat -= 0.0020;
          }

          if (_providerLng < _customerLng) {
            _providerLng += 0.0020;
          } else {
            _providerLng -= 0.0020;
          }

          // Adjust map camera view bounds
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(_providerLat, _providerLng)),
          );
        });
      }
    });
  }

  // Stepper Status Items
  final List<Map<String, dynamic>> _stepperItems = [
    {'status': 'booked', 'label': 'Booked ✅'},
    {'status': 'confirmed', 'label': 'Confirmed ⏳'},
    {'status': 'en_route', 'label': 'En Route 🚗'},
    {'status': 'arrived', 'label': 'Arrived 📍'},
    {'status': 'in_progress', 'label': 'In Progress 🔧'},
    {'status': 'completed', 'label': 'Completed ✅'},
  ];

  int _getCurrentStepIndex(String currentStatus) {
    for (int i = 0; i < _stepperItems.length; i++) {
      if (_stepperItems[i]['status'] == currentStatus) {
        return i;
      }
    }
    // Completed is terminal
    if (currentStatus == 'completed') return 5;
    return 0;
  }

  // Cancel validation
  bool _canCancelBooking(DateTime scheduledAt) {
    final diff = scheduledAt.difference(DateTime.now());
    return diff.inHours >= 24;
  }

  Future<void> _cancelBooking() async {
    try {
      final operations = ref.read(bookingOperationsProvider);
      await operations.updateStatus(widget.bookingId, 'cancelled');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking Cancelled Successfully.'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cancel failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  // Expandable review/rate dialog once completed
  void _showRateDialog(String providerId) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Rate Your Provider', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Aapka order poora ho chuka hai. Please provider ko rate karein.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Stars row selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isSelected = starIndex <= rating;
                      return IconButton(
                        icon: Icon(
                          isSelected ? Icons.star : Icons.star_border,
                          color: AppColors.gold,
                          size: 32,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            rating = starIndex;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.04),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      hintText: 'Koi comment likhein (optional)...',
                      hintStyle: const TextStyle(color: Colors.white30),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Skip', style: TextStyle(color: Colors.white30)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Update booking document in Firestore with rating & reviews
                    try {
                      final firestore = ref.read(firestoreServiceProvider);
                      await firestore.saveUser(
                        // Mock saving comments directly to booking path
                        ref.read(authProvider).currentUser!,
                      );
                      
                      // Also update booking review fields in LocalDatabase directly
                      final bData = LocalDatabase.instance.get('bookings', widget.bookingId);
                      if (bData != null) {
                        bData['rating'] = rating;
                        bData['reviewComment'] = commentController.text.trim();
                        bData['completedAt'] = DateTime.now().toIso8601String();
                        await LocalDatabase.instance.put('bookings', widget.bookingId, bData);
                      }

                      if (context.mounted) {
                        Navigator.pop(context); // close dialog
                        context.go(AppRoutes.customerHome); // go home
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Shukriya! Aap ka review save ho gaya.'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      Helpers.log('ActiveJob', 'Failed to save review: $e', isError: true);
                    }
                  },
                  child: const Text('Submit Review'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = ref.watch(firestoreServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Active Job Details', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.customerHome),
        ),
      ),
      body: StreamBuilder<BookingModel?>(
        stream: firestore.streamBooking(widget.bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Failed to load active job details.'));
          }

          final booking = snapshot.data!;
          final mockProviders = ref.read(mockProvidersProvider);
          
          // Resolve provider profile
          final provider = mockProviders.firstWhere(
            (element) => element.id == booking.providerId,
            orElse: () => ProviderModel(
              id: booking.providerId,
              name: 'Sajid Plumber',
              phone: '0312-3456789',
              password: '',
              category: booking.service,
              skillLevel: 'expert',
              cnicImageUrl: '',
              approvalStatus: 'approved',
              lat: _providerLat,
              lng: _providerLng,
              areaName: booking.customerAreaName,
              rating: 4.8,
              reviewCount: 12,
              onTimeScore: 0.98,
              cancellationRate: 0.02,
              riskScore: 0.0,
              badges: const ['Top Rated', 'Verified'],
              negativeTags: const [],
              shifts: const [],
              baseRatePkr: 500,
              pkrPerKm: 60,
              urgentSurcharge: 100,
              weeklyEarningsPending: 0.0,
              isOnline: true,
              currentLat: _providerLat,
              currentLng: _providerLng,
              createdAt: DateTime.now(),
            ),
          );

          final currentStep = _getCurrentStepIndex(booking.status);
          final showRateButton = booking.status == 'completed' && booking.rating == null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Provider details card
                _buildProviderCard(provider),
                const SizedBox(height: 20),

                // 2. Stepper Timeline Section
                const Text('Kaam Ka Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _buildStepperTimeline(currentStep),
                ),
                const SizedBox(height: 24),

                // 3. Dynamic Telemetry Map Snippet
                const Text('Live Provider Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _buildMockMap(provider),
                  ),
                ),
                const SizedBox(height: 36),

                // 4. Cancel OR Review Booking controls
                if (showRateButton) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52), backgroundColor: AppColors.secondary),
                    onPressed: () {
                      context.push(AppRoutes.customerReview, extra: booking.bookingId);
                    },
                    child: const Text('Rate Karo'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xff121224),
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold, width: 1.2),
                    ),
                    onPressed: () {
                      context.push(AppRoutes.agentLogs, extra: booking.bookingId);
                    },
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('🤖 Agent Logs Dekhein'),
                  ),
                ] else if (booking.status == 'provider_cancelled') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 32),
                        const SizedBox(height: 12),
                        Text(
                          '${provider.name} ne job cancel kar di hai. \nAgent 9 ne full refund initiate kar diya hai.',
                          style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, minimumSize: const Size(double.infinity, 48)),
                          onPressed: () {
                            context.go(AppRoutes.customerHome);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Alternative provider search started...')),
                            );
                          },
                          child: const Text('Kya aap kisi aur se book karna chahte hain?'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.customerHome),
                          child: const Text('Nahi, Home pe wapis chalo', style: TextStyle(color: Colors.white54)),
                        ),
                      ],
                    ),
                  ),
                ] else if (booking.status != 'cancelled' && booking.status != 'completed')
                  _buildCancelControlPanel(booking.scheduledAt)
                else ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: booking.status == 'cancelled' ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        booking.status == 'cancelled' ? 'Order Cancelled' : 'Order Finished & Rated Successfully',
                        style: TextStyle(
                          color: booking.status == 'cancelled' ? Colors.redAccent : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: const Color(0xff121224),
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.gold, width: 1.2),
                    ),
                    onPressed: () {
                      context.push(AppRoutes.agentLogs, extra: booking.bookingId);
                    },
                    icon: const Icon(Icons.smart_toy_outlined),
                    label: const Text('🤖 Agent Logs Dekhein'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.gold,
        icon: const Icon(Icons.fast_forward, color: AppColors.primary),
        label: const Text('Next Status', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final doc = LocalDatabase.instance.get('bookings', widget.bookingId);
          if (doc == null) return;
          final status = doc['status'] as String?;
          String next = 'confirmed';
          if (status == 'pending') next = 'confirmed';
          else if (status == 'confirmed') next = 'en_route';
          else if (status == 'en_route') next = 'arrived';
          else if (status == 'arrived') next = 'in_progress';
          else if (status == 'in_progress') next = 'payment_pending';
          else if (status == 'payment_pending') next = 'completed';
          
          doc['status'] = next;
          await LocalDatabase.instance.put('bookings', widget.bookingId, doc);
        },
      ),
    );
  }

  Widget _buildProviderCard(ProviderModel provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.gold.withOpacity(0.12),
            child: Text(
              provider.name.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.category,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: AppColors.gold),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling: ${provider.phone}')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.message, color: AppColors.gold),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat system coming soon!')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepperTimeline(int currentStep) {
    return Column(
      children: List.generate(_stepperItems.length, (index) {
        final item = _stepperItems[index];
        final isDone = index <= currentStep;
        final isActive = index == currentStep;
        
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive 
                        ? AppColors.gold 
                        : (isDone ? Colors.green : Colors.white10),
                    border: Border.all(
                      color: isActive ? AppColors.gold : Colors.transparent,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isActive 
                      ? const Icon(Icons.play_arrow, size: 14, color: AppColors.primary)
                      : (isDone 
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : const SizedBox()),
                ),
                if (index < _stepperItems.length - 1)
                  Container(
                    width: 2,
                    height: 28,
                    color: isDone ? Colors.green : Colors.white10,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: isActive 
                        ? AppColors.gold 
                        : (isDone ? Colors.white70 : Colors.white30),
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCancelControlPanel(DateTime scheduledAt) {
    final canCancel = _canCancelBooking(scheduledAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: BorderSide(color: canCancel ? Colors.redAccent : Colors.white24),
            foregroundColor: canCancel ? Colors.redAccent : Colors.white24,
          ),
          onPressed: canCancel ? _cancelBooking : null,
          child: const Text('Cancel Booking'),
        ),
        if (!canCancel)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              '⚠️ Appointment ke 24 ghante pehle cancel nahi kiya ja sakta.',
              style: TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildMockMap(ProviderModel provider) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.background],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: const GridPaper(
                color: AppColors.gold,
                interval: 40.0,
                divisions: 2,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_pin_circle,
                  color: AppColors.gold,
                  size: 40,
                ), // We will avoid flutter_animate to prevent import errors if not included
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    '${provider.name}\n(En Route)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
