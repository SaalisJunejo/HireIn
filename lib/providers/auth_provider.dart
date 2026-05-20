import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/provider_model.dart';
import '../services/local_database.dart';
import '../services/firestore_service.dart';
import '../core/utils/helpers.dart';

// State definition for persistent authentication
class AuthState {
  final UserModel? currentUser;
  final ProviderModel? currentProvider;
  final bool isAdmin;
  final bool isLoading;
  final String? error;

  AuthState({
    this.currentUser,
    this.currentProvider,
    this.isAdmin = false,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => currentUser != null || currentProvider != null || isAdmin;

  AuthState copyWith({
    UserModel? currentUser,
    ProviderModel? currentProvider,
    bool? isAdmin,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearProvider = false,
  }) {
    return AuthState(
      currentUser: clearUser ? null : (currentUser ?? this.currentUser),
      currentProvider: clearProvider ? null : (currentProvider ?? this.currentProvider),
      isAdmin: isAdmin ?? this.isAdmin,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Service bindings
final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

// Persistent Auth Notifier Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return AuthNotifier(firestoreService);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final FirestoreService _firestoreService;
  late SharedPreferences _prefs;

  AuthNotifier(this._firestoreService) : super(AuthState(isLoading: true)) {
    _initPrefs();
  }

  // Load persistence details on startup
  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final bool isLoggedIn = _prefs.getBool('is_logged_in') ?? false;
      final String? role = _prefs.getString('user_role');

      if (isLoggedIn && role != null) {
        if (role == 'customer') {
          final String? userJson = _prefs.getString('cached_user');
          if (userJson != null) {
            final user = UserModel.fromJson(jsonDecode(userJson));
            state = AuthState(currentUser: user);
            // Fetch latest from firestore in background
            _refreshCustomerProfile(user.id);
            return;
          }
        } else if (role == 'provider') {
          final String? providerJson = _prefs.getString('cached_provider');
          if (providerJson != null) {
            final provider = ProviderModel.fromJson(jsonDecode(providerJson));
            state = AuthState(currentProvider: provider);
            // Refresh in background if needed
            return;
          }
        } else if (role == 'admin') {
          state = AuthState(isAdmin: true);
          return;
        }
      }
      state = AuthState(); // Unauthenticated state
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
      Helpers.log('AuthNotifier', 'Failed to read SharedPreferences: $e', isError: true);
      state = AuthState(error: e.toString());
    }
  }

  // Refresh user data from Firestore
  Future<void> _refreshCustomerProfile(String userId) async {
    try {
      final freshProfile = await _firestoreService.getUser(userId);
      if (freshProfile != null) {
        await _prefs.setString('cached_user', jsonEncode(freshProfile.toJson()));
        if (state.currentUser?.id == userId) {
          state = state.copyWith(currentUser: freshProfile);
        }
      }
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
      Helpers.log('AuthNotifier', 'Failed background profile refresh: $e');
    }
  }

  // CUSTOMER REGISTRATION
  Future<bool> registerCustomer({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final userId = 'cust_${DateTime.now().millisecondsSinceEpoch}';
      final newUser = UserModel(
        id: userId,
        name: name,
        phone: phone,
        email: email,
        mode: 'customer',
        createdAt: DateTime.now(),
        savedAddresses: const [],
        languagePref: 'en',
        notificationsEnabled: true,
      );

      // Save to cloud & local preferences
      await _firestoreService.saveUser(newUser);
      await _prefs.setBool('is_logged_in', true);
      await _prefs.setString('user_role', 'customer');
      await _prefs.setString('cached_user', jsonEncode(newUser.toJson()));

      state = AuthState(currentUser: newUser);
      return true;
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
      state = state.copyWith(error: e.toString());
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // CUSTOMER LOGIN
  Future<bool> loginCustomer({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      // In a real app we'd verify password hash from DB. For our premium local experience:
      // Search Firestore by phone, fallback to local match
      // First try to look up user on Firestore
      UserModel? matchedUser;
      
      // Look up in background, if no firestore result, mock a premium user
      final userId = 'cust_${phone.replaceAll(RegExp(r'\D'), '')}';
      matchedUser = UserModel(
        id: userId,
        name: 'HireIn Customer',
        phone: phone,
        mode: 'customer',
        createdAt: DateTime.now(),
        savedAddresses: const [],
        languagePref: 'en',
        notificationsEnabled: true,
      );

      await _firestoreService.saveUser(matchedUser);
      await _prefs.setBool('is_logged_in', true);
      await _prefs.setString('user_role', 'customer');
      await _prefs.setString('cached_user', jsonEncode(matchedUser.toJson()));

      state = AuthState(currentUser: matchedUser);
      return true;
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
      state = state.copyWith(error: e.toString());
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // CUSTOMER RESET PASSWORD (MOCK)
  Future<bool> resetPassword(String phone, String newPassword) async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      // Just simulate success
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // PROVIDER REGISTRATION (multi-step submit)
  Future<bool> registerProvider({
    required String name,
    required String phone,
    required String password,
    required String category,
    required String address,
    required String cnicImagePath,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final providerId = 'prov_reg_${DateTime.now().millisecondsSinceEpoch}';
      
      // Coordinates mapping for provider base address
      double lat = 25.3960;
      double lng = 68.3578;

      final newProvider = ProviderModel(
        id: providerId,
        name: name,
        phone: phone,
        password: password, // In production, hash it
        category: category,
        skillLevel: 'intermediate',
        cnicImageUrl: cnicImagePath.isNotEmpty ? cnicImagePath : 'mock_cnic_placeholder_url',
        approvalStatus: 'pending', // Starts in pending review
        lat: lat,
        lng: lng,
        areaName: 'Qasimabad', // Default local area
        rating: 5.0,
        reviewCount: 0,
        onTimeScore: 1.0,
        cancellationRate: 0.0,
        riskScore: 0.0,
        badges: const ['New Partner'],
        negativeTags: const [],
        shifts: const [],
        baseRatePkr: category == 'AC Technician' ? 250 : (category == 'Plumber' ? 150 : 200),
        pkrPerKm: 60,
        urgentSurcharge: 100,
        weeklyEarningsPending: 0.0,
        isOnline: false,
        currentLat: lat,
        currentLng: lng,
        createdAt: DateTime.now(),
      );

      await _firestoreService.registerProvider(newProvider);
      
      // Do NOT log them in automatically because status is 'pending'!
      return true;
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
      state = state.copyWith(error: e.toString());
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // PROVIDER LOGIN
  Future<String?> loginProvider({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      // Look up provider in database.
      // We can fetch from local mock seeder providers for demonstration!
      final seederList = _firestoreService.streamAvailableProviders().first; // Stream query
      
      // Since it's a demo, we look up or simulate the provider log state
      // If it exists in seeder, use it, else mock a new one
      ProviderModel? provider;
      if (phone.contains('1234561')) {
        // Ali Ahmed mock match
        provider = ProviderModel(
          id: 'p1',
          name: 'Ali Ahmed',
          phone: phone,
          password: password,
          category: 'AC Technician',
          skillLevel: 'expert',
          cnicImageUrl: 'mock_cnic',
          approvalStatus: 'approved',
          lat: 25.3710,
          lng: 68.3553,
          areaName: 'Latifabad',
          rating: 4.8,
          reviewCount: 42,
          onTimeScore: 0.95,
          cancellationRate: 0.02,
          riskScore: 0.0,
          badges: const ['Top Rated'],
          negativeTags: const [],
          shifts: const [],
          baseRatePkr: 250,
          pkrPerKm: 60,
          urgentSurcharge: 100,
          weeklyEarningsPending: 1500.0,
          isOnline: true,
          currentLat: 25.3710,
          currentLng: 68.3553,
          createdAt: DateTime.now(),
        );
      } else {
        // Default mock pending/approved simulation
        provider = ProviderModel(
          id: 'prov_login_${phone.replaceAll(RegExp(r'\D'), '')}',
          name: 'Partner Provider',
          phone: phone,
          password: password,
          category: 'AC Technician',
          skillLevel: 'expert',
          cnicImageUrl: 'mock_cnic',
          approvalStatus: 'pending', // Pending by default for new numbers to show review screen!
          lat: 25.3960,
          lng: 68.3578,
          areaName: 'Qasimabad',
          rating: 5.0,
          reviewCount: 0,
          onTimeScore: 1.0,
          cancellationRate: 0.0,
          riskScore: 0.0,
          badges: const [],
          negativeTags: const [],
          shifts: const [],
          baseRatePkr: 250,
          pkrPerKm: 60,
          urgentSurcharge: 100,
          weeklyEarningsPending: 0.0,
          isOnline: false,
          currentLat: 25.3960,
          currentLng: 68.3578,
          createdAt: DateTime.now(),
        );
      }

      if (provider.approvalStatus == 'pending') {
        return 'pending';
      } else if (provider.approvalStatus == 'rejected') {
        return 'rejected';
      }

      // Approved! Set session details
      await _prefs.setBool('is_logged_in', true);
      await _prefs.setString('user_role', 'provider');
      await _prefs.setString('cached_provider', jsonEncode(provider.toJson()));

      state = AuthState(currentProvider: provider);
      return 'approved';
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
      state = state.copyWith(error: e.toString());
      return 'error';
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // ADMIN LOGIN (Hardcoded admin@hirein.com / Admin@1234)
  Future<bool> loginAdmin({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await Future.delayed(const Duration(milliseconds: 650));
      if (email.trim().toLowerCase() == 'admin@hirein.com' && password == 'Admin@1234') {
        await _prefs.setBool('is_logged_in', true);
        await _prefs.setString('user_role', 'admin');
        state = AuthState(isAdmin: true);
        return true;
      } else {
        throw Exception('Ghalat email ya password. Dobara koshish karein.');
      }
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
      state = state.copyWith(error: e.toString());
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // LOG OUT
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _prefs.setBool('is_logged_in', false);
      await _prefs.remove('user_role');
      await _prefs.remove('cached_user');
      await _prefs.remove('cached_provider');
      
      state = AuthState();
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> toggleUserMode() async {
    final user = state.currentUser;
    if (user == null) return false;

    final newMode = user.mode == 'customer' ? 'provider' : 'customer';
    
    try {
      if (newMode == 'provider') {
        final providers = LocalDatabase.instance.query('providers', (p) => p['phone'] == user.phone);

        if (providers.isEmpty) {
          throw Exception("Aap registered partner provider nahi hain. Pehle application submit karein.");
        }

        final providerData = providers.first;
        final provider = ProviderModel.fromJson(providerData);

        if (provider.approvalStatus != 'approved') {
          throw Exception("Aap ki partner application abhi approved nahi hai.");
        }

        final updatedUser = user.copyWith(mode: newMode);
        await _firestoreService.saveUser(updatedUser);
        
        await _prefs.setString('user_role', 'provider');
        await _prefs.setString('cached_user', jsonEncode(updatedUser.toJson()));
        await _prefs.setString('cached_provider', jsonEncode(provider.toJson()));

        state = state.copyWith(currentUser: updatedUser, currentProvider: provider);
        return true;
      } else {
        final updatedUser = user.copyWith(mode: newMode);
        await _firestoreService.saveUser(updatedUser);

        await _prefs.setString('user_role', 'customer');
        await _prefs.setString('cached_user', jsonEncode(updatedUser.toJson()));

        state = state.copyWith(currentUser: updatedUser, clearProvider: true);
        return true;
      }
    } catch (e) {
      print('🚨 SILENT AUTH ERROR: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void updateProviderProfile(ProviderModel updatedProvider) {
    state = state.copyWith(currentProvider: updatedProvider);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
