import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'local_database.dart';
import '../core/utils/helpers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        Helpers.log('NotificationService', 'Notification tapped: ${details.payload}');
      },
    );
    _isInitialized = true;
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'hirein_channel_id',
      'HireIn Notifications',
      channelDescription: 'HireIn mock notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelDetails =
        NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelDetails,
      payload: payload,
    );
  }

  void listenToBookingStatusChanges(String userId, BuildContext context) {
    LocalDatabase.instance.watch('bookings').listen((list) {
      final userBookings = list.where((b) => b['customerId'] == userId).toList();
      for (final data in userBookings) {
        final status = data['status'];
        final id = data['bookingId'];
        // In a real app we'd compare against previous state, but this handles mock updates
        _handleStatusChange(status, id, context);
      }
    });
  }

  void _handleStatusChange(String status, String bookingId, BuildContext context) {
    String title = '';
    String body = '';

    switch (status) {
      case 'confirmed':
        title = 'Booking Confirmed!';
        body = 'Booking ho gayi! $bookingId confirmed.';
        break;
      case 'en_route':
        title = 'Provider En Route';
        body = 'Aapka provider aa raha hai apki taraf 🚗';
        break;
      case 'completed':
        title = 'Job Completed';
        body = 'Kaam mukammal! Rate karo apna experience.';
        break;
      case 'dispute_resolved':
        title = 'Dispute Resolved';
        body = 'Aapka masla resolve ho gaya.';
        break;
      case 'provider_cancelled':
        title = 'Booking Cancelled';
        body = 'Provider ne job cancel kar di hai. Next provider select karein.';
        break;
      default:
        return; // Don't notify for other statuses
    }

    // Show local notification
    showLocalNotification(
      id: bookingId.hashCode,
      title: title,
      body: body,
      payload: bookingId,
    );

    // Show in-app banner/snackbar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(body),
            ],
          ),
          backgroundColor: const Color(0xffE8B86D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
