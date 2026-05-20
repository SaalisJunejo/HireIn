import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'auth_provider.dart';
import '../models/booking_model.dart';
import '../models/provider_model.dart';
import '../services/firestore_service.dart';
import '../core/utils/helpers.dart';

// Customer Bookings Stream Provider
final customerBookingsProvider = StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentUser = ref.watch(authProvider).currentUser;
  if (currentUser == null) return Stream.value([]);
  
  return firestoreService.streamCustomerBookings(currentUser.id);
});

// Provider Bookings Stream Provider
final providerBookingsProvider = StreamProvider.autoDispose<List<BookingModel>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final currentProvider = ref.watch(authProvider).currentProvider;
  if (currentProvider == null) return Stream.value([]);
  
  return firestoreService.streamProviderBookings(currentProvider.id);
});

// Booking Operations Notifier Provider
final bookingOperationsProvider = Provider((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return BookingOperations(firestoreService);
});

class BookingOperations {
  final FirestoreService _firestoreService;

  BookingOperations(this._firestoreService);

  Future<void> bookNewService({
    required ProviderModel provider,
    required String customerId,
    required String service,
    required double lat,
    required double lng,
    required String area,
    required double price,
    bool isUrgent = false,
  }) async {
    // Generate a random BK-XXXX formatted booking ID
    final randomNum = 1000 + Random().nextInt(9000);
    final bookingId = 'BK-$randomNum';

    final double baseFee = price > 200.0 ? 200.0 : price;
    
    // Distance calculation
    final double pLat = isUrgent ? provider.currentLat : provider.lat;
    final double pLng = isUrgent ? provider.currentLng : provider.lng;
    
    double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
      const p = 0.017453292519943295;
      final a = 0.5 - cos((lat2 - lat1) * p)/2 + 
            cos(lat1 * p) * cos(lat2 * p) * 
            (1 - cos((lng2 - lng1) * p))/2;
      return 12742 * asin(sqrt(a)); // Haversine formula
    }
    
    final dist = calculateDistance(pLat, pLng, lat, lng);
    final double travelFee = max(50.0, (dist * provider.pkrPerKm).roundToDouble());
    final double surcharge = isUrgent ? 100.0 : 0.0;
    
    final double platformFee = ((baseFee + travelFee + surcharge) / 9.0).roundToDouble();
    final double total = baseFee + travelFee + platformFee + surcharge;

    final newBooking = BookingModel(
      bookingId: bookingId,
      customerId: customerId,
      providerId: provider.id,
      service: service,
      customerLat: lat,
      customerLng: lng,
      customerAreaName: area,
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      status: 'booked',
      isUrgent: isUrgent,
      pricingBreakdown: {
        'baseFee': baseFee,
        'travelFee': travelFee,
        'urgentSurcharge': surcharge,
        'platformFee': platformFee,
        'total': total,
      },
      distanceKm: dist,
      paymentStatus: 'pending',
      createdAt: DateTime.now(),
      customerBadges: const [],
      agentLogs: const {},
    );

    try {
      await _firestoreService.createBooking(newBooking);
      Helpers.log('BookingOperations', 'Service booked successfully!');
    } catch (e) {
      Helpers.log('BookingOperations', 'Failed to create booking: $e', isError: true);
      rethrow;
    }
  }

  Future<void> updateStatus(String bookingId, String status) async {
    try {
      await _firestoreService.updateBookingStatus(bookingId, status);
      Helpers.log('BookingOperations', 'Status updated successfully to $status');
    } catch (e) {
      Helpers.log('BookingOperations', 'Failed to update status: $e', isError: true);
      rethrow;
    }
  }
}
