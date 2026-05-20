import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shake/shake.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/helpers.dart';
import 'services/notification_service.dart';
import 'services/local_database.dart';
import 'services/mock_data_seeder.dart';
import 'utils/demo_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Local Database (replaces Firebase)
  try {
    Helpers.log('main', 'Initializing Local Database...');
    await LocalDatabase.instance.init();
    Helpers.log('main', 'Local Database initialized.');
    
    // Seed mock providers on first launch
    await MockDataSeeder.seedIfEmpty();
    Helpers.log('main', 'Mock data seeding complete.');
  } catch (e) {
    Helpers.log(
      'main',
      'Local Database initialization failed: $e',
      isError: true,
    );
  }

  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: HireInApp(),
    ),
  );
}

class HireInApp extends ConsumerStatefulWidget {
  const HireInApp({super.key});

  @override
  ConsumerState<HireInApp> createState() => _HireInAppState();
}

class _HireInAppState extends ConsumerState<HireInApp> {
  ShakeDetector? _shakeDetector;
  final Connectivity _connectivity = Connectivity();
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: (event) {
        Helpers.log('main', 'Shake detected! Opening Demo Panel...');
        final router = ref.read(routerProvider);
        router.push('/demo_panel');
      },
      shakeThresholdGravity: 2.7,
      shakeCountResetTime: 3000,
      minimumShakeCount: 3,
    );

    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        setState(() => _isOffline = true);
      } else {
        setState(() => _isOffline = false);
      }
    });
  }

  @override
  void dispose() {
    _shakeDetector?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          MaterialApp.router(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: router,
          ),
          if (_isOffline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Material(
                  color: Colors.redAccent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: const Text(
                      'Internet connection nahi hai',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
