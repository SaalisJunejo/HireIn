import '../services/local_database.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_routes.dart';
import '../models/booking_model.dart';
import '../providers/auth_provider.dart';

class DemoHelper {
  static Future<void> seedDemoData() async {
    // Uses the existing streamAvailableProviders logic to ensure mock providers
    // are available or seeds them manually if needed.
    // For now, simple console print and we can use the app's existing 
    // fallback seeder.
    print('DemoHelper: seedDemoData called');
  }

  static Future<void> simulateFullBooking(String userId) async {
    final bookingId = 'BK-DEMO-9999';
    final booking = BookingModel(
      bookingId: bookingId,
      customerId: userId,
      providerId: 'PROV-001',
      service: 'AC Technician',
      customerLat: 25.3960,
      customerLng: 68.3578,
      customerAreaName: 'Qasimabad',
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      status: 'completed',
      isUrgent: true,
      pricingBreakdown: {
        'baseFee': 250,
        'travelFee': 150,
        'urgentSurcharge': 100,
        'platformFee': 50,
        'total': 550,
      },
      distanceKm: 2.5,
      paymentStatus: 'paid',
      createdAt: DateTime.now(),
      customerBadges: const ['Top Rated Customer'],
      agentLogs: {
        'BookingAgent': 'Mock completed booking for demo',
      },
    );
    
    await LocalDatabase.instance.put('bookings', bookingId, booking.toJson());
  }

  static Future<void> resetDemoState(String userId) async {
    // Delete all bookings for this user to start clean
    final bookings = LocalDatabase.instance.getAll('bookings');
    for (var b in bookings) {
      if (b['customerId'] == userId) {
        await LocalDatabase.instance.delete('bookings', b['bookingId']);
      }
    }
  }

  static Future<void> triggerScenario(BuildContext context, WidgetRef ref, int scenarioIndex) async {
    switch (scenarioIndex) {
      case 1:
        context.push(AppRoutes.customerRequest, extra: 'test_no_provider');
        break;
      case 2:
        context.push(AppRoutes.customerRequest, extra: 'help');
        break;
      case 3:
        context.push(AppRoutes.customerRequest, extra: 'AC theek karna hai');
        break;
      case 4:
        ref.read(authProvider.notifier).loginProvider(phone: '03001234561', password: 'password');
        context.go(AppRoutes.providerJobs);
        break;
      case 5:
        // Simulate a price dispute booking
        var user = ref.read(authProvider).currentUser;
        if (user == null) {
          await ref.read(authProvider.notifier).loginCustomer(phone: '03001112223', password: 'password');
          user = ref.read(authProvider).currentUser;
        }
        final userId = user?.id ?? 'CUST-999';
        final bookingId = 'BK-DISPUTE-101';
        final booking = BookingModel(
          bookingId: bookingId,
          customerId: userId,
          providerId: 'PROV-002',
          service: 'Electrician',
          customerLat: 25.3960,
          customerLng: 68.3578,
          customerAreaName: 'Qasimabad',
          scheduledAt: DateTime.now().subtract(const Duration(days: 1)),
          status: 'disputed',
          isUrgent: false,
          pricingBreakdown: {
            'baseFee': 500,
            'travelFee': 100,
            'total': 600,
          },
          distanceKm: 3.0,
          paymentStatus: 'pending',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          reviewComment: 'Provider charged 1000 PKR instead of 600 PKR! Fraud!',
          agentLogs: const {},
          customerBadges: const [],
        );
        await LocalDatabase.instance.put('bookings', bookingId, booking.toJson());
        
        await LocalDatabase.instance.put('disputes', bookingId, {
          'bookingId': bookingId,
          'customerId': userId,
          'providerId': 'PROV-002',
          'reason': 'Overcharged',
          'description': 'He took 1000 instead of 600',
          'status': 'open',
          'createdAt': DateTime.now().toIso8601String(),
          'agentDecision': null,
        });

        if (context.mounted) {
          context.push(AppRoutes.customerBookingHistory);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Disputed booking generated! View in Completed tab.')),
          );
        }
        break;
    }
  }
}
