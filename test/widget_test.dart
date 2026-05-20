import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hirein/screens/auth/welcome_screen.dart';

void main() {
  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    // Build our welcome screen in a mock MaterialApp.
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    // Let the animations run and settle.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    // Verify that the welcome screen branding shows up.
    expect(find.text('HireIn'), findsOneWidget);
    expect(find.text('Pakistan ka Smart Service App'), findsOneWidget);
    
    // Verify that onboarding choices are present.
    expect(find.text('Mujhe Service Chahiye'), findsOneWidget);
    expect(find.text('Main Service Provider Hoon'), findsOneWidget);
    expect(find.text('Admin Login'), findsOneWidget);
  });
}
