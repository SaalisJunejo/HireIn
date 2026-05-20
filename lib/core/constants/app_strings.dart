class AppStrings {
  AppStrings._();

  // App Meta
  static const String appName = 'HireIn';
  static const String tagline = 'AI-Powered Service Hub for Hyderabad';
  static const String poweredBy = 'Powered by Google Antigravity + Gemini AI + Local-First Architecture';
  static const String challenge = 'Google Antigravity Hackathon — Challenge 2';

  // Geographic Constraints - STRICTLY HYDERABAD, SINDH, PAKISTAN
  static const double hyderabadLat = 25.3960;
  static const double hyderabadLng = 68.3578;
  static const String defaultCity = 'Hyderabad, Sindh';
  static const String defaultCountry = 'Pakistan';

  // Hyderabad Areas (Strict List)
  static const List<String> hyderabadAreas = [
    'Latifabad',
    'Qasimabad',
    'Hirabad',
    'Unit 9',
    'Saddar',
    'Unit 6',
    'Unit 7',
    'Unit 8',
    'Unit 10',
    'Unit 11',
    'Unit 12',
    'Hyder Chowk',
    'Shahi Bazar',
  ];

  // Auth Strings
  static const String welcomeMessage = 'Bismillah-ir-Rahman-ir-Rahim\nWelcome to HireIn';
  static const String subWelcomeMessage = 'Hyderabad\'s local service marketplace at your fingertips, powered by Agentic AI.';
  static const String enterPhone = 'Enter your phone number to proceed';
  static const String getStarted = 'Get Started';
  static const String verifyOtp = 'Verify OTP';
  static const String otpSentMessage = 'A 6-digit code has been sent to your phone.';
  static const String verificationFailed = 'OTP verification failed. Please try again.';

  // Service Categories
  static const List<String> serviceCategories = [
    'Electrician',
    'Plumber',
    'Carpenter',
    'Tailor (Darzi)',
    'AC Repair',
    'Mechanic',
    'Home Maid',
    'Painter',
  ];
}
