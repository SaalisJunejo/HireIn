import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Premium Navy and Gold Palette
  static const Color primary = Color(0xff1A1A2E);       // Deep navy
  static const Color secondary = Color(0xffE8B86D);     // Gold
  static const Color accent = Color(0xff16213E);        // Dark navy
  static const Color background = Color(0xff0F0F1A);    // Near black
  static const Color surface = Color(0xff1E1E30);       // Card background

  // System States
  static const Color success = Color(0xff4CAF50);
  static const Color error = Color(0xffF44336);

  // Typography Colors
  static const Color textPrimary = Color(0xffFFFFFF);
  static const Color textSecondary = Color(0xffA0A0B0);

  // Accent Golds (for visual richness, gradients, overlays)
  static const Color gold = Color(0xffE8B86D);
  static const Color goldLight = Color(0xffF3D39C);
  static const Color goldDark = Color(0xffC1964D);

  // Gradients for UI elements
  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldDark, gold, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient navyGradient = LinearGradient(
    colors: [primary, accent, background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [surface, Color(0xff25253D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
