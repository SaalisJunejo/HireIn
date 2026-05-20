import 'mock_data_seeder.dart';
import '../models/provider_model.dart';

class MockService {
  MockService._();

  // Hyderabad City Center: Lat 25.3960, Lng 68.3578
  static const double hyderabadLat = MockDataSeeder.baseLat;
  static const double hyderabadLng = MockDataSeeder.baseLng;

  // Hyderabad specific areas
  static final List<Map<String, dynamic>> hyderabadLocations = MockDataSeeder.hyderabadAreas.entries.map((entry) {
    return {
      'name': entry.key,
      'latOffset': entry.value['lat']! - hyderabadLat,
      'lngOffset': entry.value['lng']! - hyderabadLng,
    };
  }).toList();

  static List<ProviderModel> generateMockProviders() {
    return MockDataSeeder.getMockProviders();
  }
}
