import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:risdi/model/stakeholder_contact_model.dart';
import 'package:risdi/screens/screen.dart';
import 'package:risdi/web_admin/screens/web_admin_dashboard.dart';
import 'package:risdi/component/auth_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:risdi/services/stakeholder_cache_service.dart';
import 'package:risdi/core/constants/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local services only (Hive, SharedPreferences)
  bool hasSeenOnboarding = false;
  
  if (!kIsWeb) {
    try {
      await Hive.initFlutter();
      Hive.registerAdapter(StakeholderAdapter());

      // Initialize cache service
      final cacheService = StakeholderCacheService();
      await cacheService.initialize();

      // Check if the onboarding has been seen
      SharedPreferences prefs = await SharedPreferences.getInstance();
      hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    } catch (e) {
      debugPrint('Error initializing local services: $e');
    }
  } else {
    // Web platform - just get onboarding status
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    } catch (e) {
      debugPrint('Error getting onboarding status: $e');
    }
  }

  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      // Platform-specific routing
      home: kIsWeb
          ? const WebAuthWrapper()
          : SplashScreen(hasSeenOnboarding: hasSeenOnboarding),
    );
  }
}

/// Web authentication wrapper to check if user is logged in
class WebAuthWrapper extends StatelessWidget {
  const WebAuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, show admin dashboard
        if (snapshot.hasData) {
          return const WebAdminDashboard();
        }

        // Otherwise, show login screen
        return const AuthScreen();
      },
    );
  }
}
