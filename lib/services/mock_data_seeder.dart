import 'dart:math';
import '../models/provider_model.dart';
import '../core/utils/helpers.dart';
import 'local_database.dart';

class MockDataSeeder {
  MockDataSeeder._();

  // Hyderabad center
  static const double baseLat = 25.3960;
  static const double baseLng = 68.3578;

  // Strict list of approved Hyderabad areas mapped to coordinate offsets
  static final Map<String, Map<String, double>> hyderabadAreas = {
    'Latifabad': {'lat': 25.3710, 'lng': 68.3553},
    'Qasimabad': {'lat': 25.4080, 'lng': 68.3398},
    'Hirabad': {'lat': 25.4040, 'lng': 68.3758},
    'Unit 9': {'lat': 25.3810, 'lng': 68.3528},
    'Saddar': {'lat': 25.3910, 'lng': 68.3628},
    'Unit 6': {'lat': 25.3740, 'lng': 68.3458},
    'Unit 7': {'lat': 25.3680, 'lng': 68.3498},
    'Unit 8': {'lat': 25.3780, 'lng': 68.3568},
    'Unit 10': {'lat': 25.3640, 'lng': 68.3438},
    'Unit 11': {'lat': 25.3610, 'lng': 68.3478},
    'Unit 12': {'lat': 25.3700, 'lng': 68.3598},
    'Hyder Chowk': {'lat': 25.3980, 'lng': 68.3658},
    'Shahi Bazar': {'lat': 25.4010, 'lng': 68.3700},
  };

  // Base rates mapped by category
  static final Map<String, int> baseRates = {
    'AC Technician': 250,
    'Plumber': 150,
    'Electrician': 200,
    'Carpenter': 200,
    'Mechanic': 250,
    'Painter': 150,
  };

  // 20 Mock Providers defined exactly as requested
  static List<ProviderModel> getMockProviders() {
    final DateTime today = DateTime.now();
    final DateTime tomorrow = today.add(const Duration(days: 1));

    // Dynamic shift generator helper
    List<Map<String, dynamic>> generateShifts() {
      final String todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final String tomorrowStr = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
      return [
        {'date': todayStr, 'startTime': '09:00', 'endTime': '17:00'},
        {'date': tomorrowStr, 'startTime': '10:00', 'endTime': '18:00'}
      ];
    }

    final rawProvidersData = [
      // 1. Ali Ahmed — AC Technician — Latifabad — rating 4.8
      {
        'id': 'p1',
        'name': 'Ali Ahmed',
        'phone': '+923001234561',
        'category': 'AC Technician',
        'areaName': 'Latifabad',
        'rating': 4.8,
        'skillLevel': 'expert'
      },
      // 2. Hassan Khan — Plumber — Qasimabad — rating 4.5
      {
        'id': 'p2',
        'name': 'Hassan Khan',
        'phone': '+923001234562',
        'category': 'Plumber',
        'areaName': 'Qasimabad',
        'rating': 4.5,
        'skillLevel': 'intermediate'
      },
      // 3. Imran Shaikh — Electrician — Saddar — rating 4.2
      {
        'id': 'p3',
        'name': 'Imran Shaikh',
        'phone': '+923001234563',
        'category': 'Electrician',
        'areaName': 'Saddar',
        'rating': 4.2,
        'skillLevel': 'intermediate'
      },
      // 4. Bilal Hussain — Carpenter — Hirabad — rating 4.7
      {
        'id': 'p4',
        'name': 'Bilal Hussain',
        'phone': '+923001234564',
        'category': 'Carpenter',
        'areaName': 'Hirabad',
        'rating': 4.7,
        'skillLevel': 'expert'
      },
      // 5. Kamran Ali — Mechanic — Unit 9 — rating 4.0
      {
        'id': 'p5',
        'name': 'Kamran Ali',
        'phone': '+923001234565',
        'category': 'Mechanic',
        'areaName': 'Unit 9',
        'rating': 4.0,
        'skillLevel': 'basic'
      },
      // 6. Faisal Memon — Painter — Qasimabad — rating 4.6 (Mapped from Gulshan-e-Iqbal)
      {
        'id': 'p6',
        'name': 'Faisal Memon',
        'phone': '+923001234566',
        'category': 'Painter',
        'areaName': 'Qasimabad',
        'rating': 4.6,
        'skillLevel': 'expert'
      },
      // 7. Rasheed Ahmed — AC Technician — Saddar — rating 3.9
      {
        'id': 'p7',
        'name': 'Rasheed Ahmed',
        'phone': '+923001234567',
        'category': 'AC Technician',
        'areaName': 'Saddar',
        'rating': 3.9,
        'skillLevel': 'intermediate'
      },
      // 8. Sajid Khan — Plumber — Latifabad — rating 4.1
      {
        'id': 'p8',
        'name': 'Sajid Khan',
        'phone': '+923001234568',
        'category': 'Plumber',
        'areaName': 'Latifabad',
        'rating': 4.1,
        'skillLevel': 'intermediate'
      },
      // 9. Zeeshan Qureshi — Electrician — Hirabad — rating 4.9
      {
        'id': 'p9',
        'name': 'Zeeshan Qureshi',
        'phone': '+923001234569',
        'category': 'Electrician',
        'areaName': 'Hirabad',
        'rating': 4.9,
        'skillLevel': 'expert'
      },
      // 10. Aslam Soomro — Carpenter — Unit 6 — rating 3.7
      {
        'id': 'p10',
        'name': 'Aslam Soomro',
        'phone': '+923001234570',
        'category': 'Carpenter',
        'areaName': 'Unit 6',
        'rating': 3.7,
        'skillLevel': 'basic'
      },
      // 11. Fahad Mallah — Mechanic — Unit 7 — rating 4.3
      {
        'id': 'p11',
        'name': 'Fahad Mallah',
        'phone': '+923001234571',
        'category': 'Mechanic',
        'areaName': 'Unit 7',
        'rating': 4.3,
        'skillLevel': 'intermediate'
      },
      // 12. Bilal Soomro — Painter — Unit 8 — rating 3.5
      {
        'id': 'p12',
        'name': 'Bilal Soomro',
        'phone': '+923001234572',
        'category': 'Painter',
        'areaName': 'Unit 8',
        'rating': 3.5,
        'skillLevel': 'basic'
      },
      // 13. Tariq Lashari — AC Technician — Unit 10 — rating 4.4
      {
        'id': 'p13',
        'name': 'Tariq Lashari',
        'phone': '+923001234573',
        'category': 'AC Technician',
        'areaName': 'Unit 10',
        'rating': 4.4,
        'skillLevel': 'intermediate'
      },
      // 14. Naveed Chang — Plumber — Unit 11 — rating 4.0
      {
        'id': 'p14',
        'name': 'Naveed Chang',
        'phone': '+923001234574',
        'category': 'Plumber',
        'areaName': 'Unit 11',
        'rating': 4.0,
        'skillLevel': 'intermediate'
      },
      // 15. Mustafa Shah — Electrician — Unit 12 — rating 4.7
      {
        'id': 'p15',
        'name': 'Mustafa Shah',
        'phone': '+923001234575',
        'category': 'Electrician',
        'areaName': 'Unit 12',
        'rating': 4.7,
        'skillLevel': 'expert'
      },
      // 16. Yasir Arafat — Carpenter — Hyder Chowk — rating 4.1
      {
        'id': 'p16',
        'name': 'Yasir Arafat',
        'phone': '+923001234576',
        'category': 'Carpenter',
        'areaName': 'Hyder Chowk',
        'rating': 4.1,
        'skillLevel': 'intermediate'
      },
      // 17. Junaid Memon — Mechanic — Shahi Bazar — rating 4.6
      {
        'id': 'p17',
        'name': 'Junaid Memon',
        'phone': '+923001234577',
        'category': 'Mechanic',
        'areaName': 'Shahi Bazar',
        'rating': 4.6,
        'skillLevel': 'expert'
      },
      // 18. Rafique Pehlwan — Painter — Latifabad — rating 3.8
      {
        'id': 'p18',
        'name': 'Rafique Pehlwan',
        'phone': '+923001234578',
        'category': 'Painter',
        'areaName': 'Latifabad',
        'rating': 3.8,
        'skillLevel': 'basic'
      },
      // 19. Waqar Ali — AC Technician — Qasimabad — rating 4.5
      {
        'id': 'p19',
        'name': 'Waqar Ali',
        'phone': '+923001234579',
        'category': 'AC Technician',
        'areaName': 'Qasimabad',
        'rating': 4.5,
        'skillLevel': 'intermediate'
      },
      // 20. Haris Qureshi — Plumber — Saddar — rating 4.2
      {
        'id': 'p20',
        'name': 'Haris Qureshi',
        'phone': '+923001234580',
        'category': 'Plumber',
        'areaName': 'Saddar',
        'rating': 4.2,
        'skillLevel': 'intermediate'
      },
    ];

    return rawProvidersData.map((data) {
      final area = data['areaName'] as String;
      final coords = hyderabadAreas[area] ?? {'lat': baseLat, 'lng': baseLng};
      final category = data['category'] as String;
      final baseRate = baseRates[category] ?? 150;

      return ProviderModel(
        id: data['id'] as String,
        name: data['name'] as String,
        phone: data['phone'] as String,
        password: 'hashed_password_placeholder', // Simulation placeholder
        category: category,
        skillLevel: data['skillLevel'] as String,
        cnicImageUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=200', // Premium mockup
        approvalStatus: 'approved',
        lat: coords['lat']!,
        lng: coords['lng']!,
        areaName: area,
        rating: data['rating'] as double,
        reviewCount: 10 + Random().nextInt(50),
        onTimeScore: 0.85 + Random().nextDouble() * 0.15,
        cancellationRate: Random().nextDouble() * 0.10,
        riskScore: Random().nextDouble() * 0.05,
        badges: ['Top Rated', 'Verified Service'],
        negativeTags: [],
        shifts: generateShifts(),
        baseRatePkr: baseRate,
        pkrPerKm: 60,
        urgentSurcharge: 100,
        weeklyEarningsPending: 0.0,
        isOnline: true,
        currentLat: coords['lat']! + (Random().nextDouble() - 0.5) * 0.005,
        currentLng: coords['lng']! + (Random().nextDouble() - 0.5) * 0.005,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
    }).toList();
  }

  /// Only seed if the providers collection is empty (first launch guard)
  static Future<void> seedIfEmpty() async {
    final existing = LocalDatabase.instance.getAll('providers');
    if (existing.isNotEmpty) {
      Helpers.log('MockDataSeeder', 'Providers already exist (${existing.length}), skipping seed.');
      return;
    }
    await seedLocalDatabase();
  }

  static Future<void> seedLocalDatabase() async {
    try {
      Helpers.log('MockDataSeeder', 'Seeding 20 mock providers to LocalDatabase...');
      final List<ProviderModel> providersList = getMockProviders();
      
      for (final provider in providersList) {
        await LocalDatabase.instance.put('providers', provider.id, provider.toJson());
      }
      Helpers.log('MockDataSeeder', 'Seeding complete. 20 providers published online.');
    } catch (e) {
      Helpers.log('MockDataSeeder', 'Local seed failed/skipped: $e', isError: true);
    }
  }
}
