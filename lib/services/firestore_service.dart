import '../models/provider_model.dart';
import '../models/booking_model.dart';
import '../models/user_model.dart';
import 'local_database.dart';

class FirestoreService {
  FirestoreService();

  // --- Users ---
  Future<void> createUser(UserModel user) async {
    await LocalDatabase.instance.put('users', user.id, user.toJson());
  }

  Future<UserModel?> getUser(String uid) async {
    final data = LocalDatabase.instance.get('users', uid);
    if (data == null) return null;
    return UserModel.fromJson(data);
  }

  // --- Providers ---
  Stream<List<ProviderModel>> streamAvailableProviders({String? category}) {
    return LocalDatabase.instance.watch('providers').map((list) {
      var providers = list.map((e) => ProviderModel.fromJson(e)).toList();
      if (category != null) {
        providers = providers.where((p) => p.category == category).toList();
      }
      return providers;
    });
  }
  
  Future<ProviderModel?> getProvider(String providerId) async {
    final data = LocalDatabase.instance.get('providers', providerId);
    if (data == null) return null;
    return ProviderModel.fromJson(data);
  }

  Future<void> updateProviderStatus(String providerId, bool isOnline) async {
    final data = LocalDatabase.instance.get('providers', providerId);
    if (data != null) {
      data['isOnline'] = isOnline;
      await LocalDatabase.instance.put('providers', providerId, data);
    }
  }

  Future<void> registerProvider(ProviderModel provider) async {
    await LocalDatabase.instance.put('providers', provider.id, provider.toJson());
  }

  // --- Bookings ---
  Future<void> createBooking(BookingModel booking) async {
    await LocalDatabase.instance.put('bookings', booking.bookingId, booking.toJson());
  }

  Stream<List<BookingModel>> streamCustomerBookings(String customerId) {
    return LocalDatabase.instance.watch('bookings').map((list) {
      return list
          .where((e) => e['customerId'] == customerId)
          .map((e) => BookingModel.fromJson(e))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Stream<List<BookingModel>> streamProviderBookings(String providerId) {
    return LocalDatabase.instance.watch('bookings').map((list) {
      return list
          .where((e) => e['providerId'] == providerId)
          .map((e) => BookingModel.fromJson(e))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    final data = LocalDatabase.instance.get('bookings', bookingId);
    if (data != null) {
      data['status'] = status;
      await LocalDatabase.instance.put('bookings', bookingId, data);
    }
  }

  /// Stream a single booking by ID (reactive)
  Stream<BookingModel?> streamBooking(String bookingId) {
    return LocalDatabase.instance.watch('bookings').map((list) {
      final match = list.where((e) => e['bookingId'] == bookingId).toList();
      if (match.isEmpty) return null;
      return BookingModel.fromJson(match.first);
    });
  }

  /// Save/update a user document
  Future<void> saveUser(UserModel user) async {
    await LocalDatabase.instance.put('users', user.id, user.toJson());
  }
}
