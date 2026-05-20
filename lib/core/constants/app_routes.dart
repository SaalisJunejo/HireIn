import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import 'app_strings.dart';

// Screens import stubs (these will map to our new premium screens)
import '../../screens/auth/welcome_screen.dart';
import '../../screens/auth/customer_login_screen.dart';
import '../../screens/auth/customer_register_screen.dart';
import '../../screens/admin/admin_approval_screen.dart';
import '../../screens/demo_panel_screen.dart';
import '../../screens/auth/provider_login_screen.dart';
import '../../screens/auth/provider_register_screen.dart';
import '../../screens/auth/admin_login_screen.dart';
import '../../screens/customer/customer_home_screen.dart';
import '../../screens/customer/service_request_flow_screen.dart';
import '../../screens/customer/booking_screen.dart';
import '../../screens/customer/active_job_screen.dart';
import '../../screens/customer/review_screen.dart';
import '../../screens/customer/booking_history_screen.dart';
import '../../screens/provider/provider_dashboard_screen.dart';
import '../../screens/provider/provider_job_details_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/customer/agent_logs_screen.dart';
import '../../models/provider_model.dart';

class AppRoutes {
  AppRoutes._();

  // Primary Paths
  static const String splash = '/';
  
  // Auth Sub-routes
  static const String customerLogin = '/auth/customer/login';
  static const String customerRegister = '/auth/customer/register';
  static const String providerLogin = '/auth/provider/login';
  static const String providerRegister = '/auth/provider/register';
  static const String adminLogin = '/auth/admin/login';
  
  // Dashboard routes
  static const String customerHome = '/customer';
  static const String customerMap = '/customer/map';
  static const String customerRequest = '/customer/request';
  static const String customerActiveJob = '/customer/active-job';
  static const String customerBookingHistory = '/customer/history';
  static const String customerReview = '/customer/review';
  static const String providerHome = '/provider';
  static const String providerJobs = '/provider/jobs';
  static const String providerJobDetails = '/provider/job-details';
  static const String adminHome = '/admin';
  static const String agentLogs = '/customer/agent-logs';
}

// Router provider exposing GoRouter linked directly to Riverpod's authState
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final bool loading = authState.isLoading;
      if (loading) return null; // Wait until persistence is resolved

      final bool authenticated = authState.isAuthenticated;
      final String loc = state.matchedLocation;
      final bool isGoingToAuth = loc == AppRoutes.splash || loc.startsWith('/auth');

      // GUARD 1: Unauthenticated users must land on Splash/Welcome/Auth screens
      if (!authenticated) {
        return isGoingToAuth ? null : AppRoutes.splash;
      }

      // GUARD 2: Authenticated users should not visit auth screens, auto-route to proper dashboards
      if (isGoingToAuth) {
        if (authState.isAdmin) {
          return AppRoutes.adminHome;
        } else if (authState.currentProvider != null) {
          return AppRoutes.providerHome;
        } else if (authState.currentUser != null) {
          return AppRoutes.customerHome;
        }
      }

      return null; // Keep current path
    },
    routes: [
      // Screen 1: Welcome/Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const WelcomeScreen(),
      ),
      // Screen 2: Customer Registration
      GoRoute(
        path: AppRoutes.customerRegister,
        builder: (context, state) => const CustomerRegisterScreen(),
      ),
      // Screen 3: Customer Login
      GoRoute(
        path: AppRoutes.customerLogin,
        builder: (context, state) => const CustomerLoginScreen(),
      ),
      // Screen 4: Provider Registration
      GoRoute(
        path: AppRoutes.providerRegister,
        builder: (context, state) => const ProviderRegisterScreen(),
      ),
      // Screen 5: Provider Login
      GoRoute(
        path: AppRoutes.providerLogin,
        builder: (context, state) => const ProviderLoginScreen(),
      ),
      GoRoute(
        path: '/demo_panel',
        builder: (context, state) => const DemoPanelScreen(),
      ),
      // Screen 6: Admin Login
      GoRoute(
        path: AppRoutes.adminLogin,
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // Customer Dashboard
      GoRoute(
        path: AppRoutes.customerHome,
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerMap,
        builder: (context, state) => const _PlaceholderScreen(title: 'Customer Map'),
      ),
      GoRoute(
        path: AppRoutes.customerRequest,
        builder: (context, state) {
          final initialQuery = state.extra as String?;
          return ServiceRequestFlowScreen(initialQuery: initialQuery);
        },
      ),
      GoRoute(
        path: '/customer/booking',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          final provider = extra['provider'] as ProviderModel;
          final isUrgent = extra['isUrgent'] as bool;
          final userLat = extra['userLat'] as double? ?? AppStrings.hyderabadLat;
          final userLng = extra['userLng'] as double? ?? AppStrings.hyderabadLng;
          final userArea = extra['userArea'] as String? ?? provider.areaName;
          return BookingScreen(
            provider: provider,
            isUrgent: isUrgent,
            userLat: userLat,
            userLng: userLng,
            userArea: userArea,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.customerActiveJob,
        builder: (context, state) {
          final bookingId = state.extra as String;
          return ActiveJobScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: AppRoutes.customerBookingHistory,
        builder: (context, state) => const BookingHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerReview,
        builder: (context, state) {
          final bookingId = state.extra as String;
          return ReviewScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: AppRoutes.agentLogs,
        builder: (context, state) {
          final bookingId = state.extra as String?;
          return AgentLogsScreen(bookingId: bookingId);
        },
      ),
      
      // Provider Dashboard Screen
      GoRoute(
        path: AppRoutes.providerHome,
        builder: (context, state) => const ProviderDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.providerJobs,
        builder: (context, state) => const _PlaceholderScreen(title: 'Provider Active Jobs'),
      ),
      GoRoute(
        path: AppRoutes.providerJobDetails,
        builder: (context, state) {
          final bookingId = state.extra as String;
          return ProviderJobDetailsScreen(bookingId: bookingId);
        },
      ),

      // Admin Dashboard
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});

// Temporary private placeholder screen to prevent GoRouter compilation errors.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F1A),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Interactive Dashboard Placeholder with Logout button for easy testing!
class _DashboardPlaceholder extends StatelessWidget {
  final String title;
  final VoidCallback onLogout;

  const _DashboardPlaceholder({required this.title, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xff0F0F1A),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xffE8B86D)),
            onPressed: onLogout,
            tooltip: 'Log Out',
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: Color(0xffE8B86D)),
            const SizedBox(height: 24),
            Text(
              'Aap ${title} par hain!',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Authentication system successfully verified this role.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffE8B86D),
                foregroundColor: const Color(0xff0F0F1A),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              onPressed: onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Log Out Karein'),
            )
          ],
        ),
      ),
    );
  }
}
