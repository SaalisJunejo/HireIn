import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Helpers {
  Helpers._();

  // Localized Currency Formatter (PKR)
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Localized Date Formatter
  static String formatDate(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  // Haversine formula to calculate distance between coordinates (in km)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // Custom Debug Logger with Visual Indicators
  static void log(String tag, String message, {bool isError = false}) {
    final emoji = isError ? '❌ [ERROR]' : '⚡ [HireIn]';
    final timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
    // ignore: avoid_print
    print('[$timestamp] $emoji ($tag) -> $message');
  }

  // Quick responsive layout helpers
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;

  // Visual feedback helpers
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? const Color(0xffF44336) : const Color(0xff1E1E30),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
