import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/local_database.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking_model.dart';
import '../../core/utils/helpers.dart';

class ProviderJobDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const ProviderJobDetailsScreen({super.key, required this.bookingId});

  @override
  ConsumerState<ProviderJobDetailsScreen> createState() => _ProviderJobDetailsScreenState();
}

class _ProviderJobDetailsScreenState extends ConsumerState<ProviderJobDetailsScreen> {
  Timer? _driftTimer;
  double _provLat = 25.3710;
  double _provLng = 68.3553;

  @override
  void dispose() {
    _driftTimer?.cancel();
    super.dispose();
  }

  void _startLocationSimulation(String providerId, double destLat, double destLng) {
    _driftTimer?.cancel();
    
    // Initial coords set to Ali Ahmed starting location
    _provLat = 25.3710;
    _provLng = 68.3553;

    _driftTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final double diffLat = destLat - _provLat;
      final double diffLng = destLng - _provLng;

      if (diffLat.abs() < 0.0001 && diffLng.abs() < 0.0001) {
        _driftTimer?.cancel();
        Helpers.log('ProviderJob', 'Coordinates simulation arrived at customer destination.');
        return;
      }

      // Progress 20% closer per tick
      _provLat += diffLat * 0.2;
      _provLng += diffLng * 0.2;

      try {
        final pData = LocalDatabase.instance.get('providers', providerId);
        if (pData != null) {
          pData['currentLat'] = _provLat;
          pData['currentLng'] = _provLng;
          await LocalDatabase.instance.put('providers', providerId, pData);
        }
        Helpers.log('ProviderJob', 'Background coordinate drift: $_provLat, $_provLng');
      } catch (e) {
        Helpers.log('ProviderJob', 'Failed to update simulated coordinates: $e');
      }
    });
  }

  Future<void> _updateJobStatus(BookingModel booking, String newStatus) async {
    final operations = ref.read(bookingOperationsProvider);
    final providerId = booking.providerId;

    try {
      await operations.updateStatus(booking.bookingId, newStatus);
      
      // If status is en_route, trigger live coordinate simulation drift
      if (newStatus == 'en_route') {
        _startLocationSimulation(providerId, booking.customerLat, booking.customerLng);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚗 Live tracking simulation started! Coords updating in background.'),
            backgroundColor: AppColors.gold,
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Status updated successfully to: ${newStatus.toUpperCase()}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Job Details',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<BookingModel?>(
        stream: ref.read(firestoreServiceProvider).streamBooking(widget.bookingId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold));
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Job details load karne mein masla hua.'));
          }

          final booking = snapshot.data!;
          final double total = booking.pricingBreakdown['total']?.toDouble() ?? 0.0;
          final double platformFee = booking.pricingBreakdown['platformFee']?.toDouble() ?? 30.0;
          final double earnings = total - platformFee;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Interactive Dark Styled Google Map
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(booking.customerLat, booking.customerLng),
                      zoom: 14.5,
                    ),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    mapType: MapType.normal,
                    markers: {
                      Marker(
                        markerId: const MarkerId('customer'),
                        position: LatLng(booking.customerLat, booking.customerLng),
                        infoWindow: InfoWindow(title: 'Customer: ${booking.customerAreaName}'),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      ),
                    },
                    onMapCreated: (GoogleMapController controller) {
                      // Apply standard premium dark style JSON
                      controller.setMapStyle('''
                      [
                        { "elementType": "geometry", "stylers": [ { "color": "#1A1A2E" } ] },
                        { "elementType": "labels.text.stroke", "stylers": [ { "color": "#1A1A2E" } ] },
                        { "elementType": "labels.text.fill", "stylers": [ { "color": "#746855" } ] },
                        { "featureType": "road", "elementType": "geometry", "stylers": [ { "color": "#16213E" } ] }
                      ]
                      ''');
                    },
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Customer Name & Category Summary Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(booking.service, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 4),
                              Text('📍 Area: ${booking.customerAreaName}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            ],
                          ),
                          _buildStatusBadge(booking.status),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Customer Phone details with mock click
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.person_outline, color: AppColors.gold, size: 20),
                                SizedBox(width: 12),
                                Text(
                                  'Customer Contact',
                                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.call, size: 16),
                              label: const Text('Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('📱 Dialing customer... (0300-1234567)')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3. Earnings breakdown rows
                      const Text('EARNINGS BREAKDOWN', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Column(
                          children: [
                            _buildPriceRow('Total Service Fee', 'PKR ${total.toStringAsFixed(0)}'),
                            const SizedBox(height: 10),
                            _buildPriceRow('Platform Cut (10%)', '- PKR ${platformFee.toStringAsFixed(0)}', valueColor: Colors.redAccent),
                            const Divider(color: Colors.white10, height: 24),
                            _buildPriceRow('Your Earnings', 'PKR ${earnings.toStringAsFixed(0)}', valueColor: Colors.green, isBold: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),

                      // 4. Transitions Status buttons
                      const Text('STATUS UPDATE', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      const SizedBox(height: 12),

                      _buildStatusTransitionButtons(booking),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {Color valueColor = Colors.white70, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isBold ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: valueColor, fontSize: isBold ? 16 : 13, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.green;
    if (status == 'booked' || status == 'confirmed') {
      color = AppColors.gold;
    } else if (status == 'en_route' || status == 'arrived' || status == 'in_progress') {
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _buildStatusTransitionButtons(BookingModel booking) {
    final String currentStatus = booking.status;

    if (currentStatus == 'completed' || currentStatus == 'provider_cancelled' || currentStatus == 'cancelled') {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: currentStatus == 'completed' ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            currentStatus == 'completed' ? 'This job is completed.' : 'This job is cancelled.',
            style: TextStyle(color: currentStatus == 'completed' ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    Widget primaryButton = const SizedBox();

    if (currentStatus == 'booked') {
      primaryButton = ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52), backgroundColor: AppColors.secondary),
        onPressed: () => _updateJobStatus(booking, 'confirmed'),
        child: const Text('Confirm Karo'),
      );
    } else if (currentStatus == 'confirmed') {
      primaryButton = ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52), backgroundColor: AppColors.secondary),
        onPressed: () => _updateJobStatus(booking, 'en_route'),
        child: const Text('Main Ja Raha Hoon (En Route)'),
      );
    } else if (currentStatus == 'en_route') {
      primaryButton = ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52), backgroundColor: AppColors.secondary),
        onPressed: () => _updateJobStatus(booking, 'arrived'),
        child: const Text('Pahunch Gaya (Arrived)'),
      );
    } else if (currentStatus == 'arrived') {
      primaryButton = ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52), backgroundColor: AppColors.secondary),
        onPressed: () => _updateJobStatus(booking, 'in_progress'),
        child: const Text('Kaam Shuru (In Progress)'),
      );
    } else if (currentStatus == 'in_progress') {
      primaryButton = ElevatedButton(
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52), backgroundColor: AppColors.secondary),
        onPressed: () => _updateJobStatus(booking, 'completed'),
        child: const Text('Kaam Mukammal (Completed)'),
      );
    }

    return Column(
      children: [
        primaryButton,
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
            side: const BorderSide(color: Colors.redAccent),
            foregroundColor: Colors.redAccent,
          ),
          onPressed: () => _updateJobStatus(booking, 'provider_cancelled'),
          child: const Text('Cancel Job'),
        ),
      ],
    );
  }
}
