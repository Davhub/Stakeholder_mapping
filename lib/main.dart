import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:risdi/model/stakeholder_contact_model.dart';
import 'package:risdi/screens/screen.dart';
import 'package:risdi/web_admin/screens/web_admin_dashboard.dart';
import 'package:risdi/component/auth_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:risdi/services/stakeholder_cache_service.dart';
import 'package:risdi/core/constants/constants.dart';

/// Roles permitted to use the web admin dashboard. Regular mobile-app
/// signups default to the 'User' role and must never see this UI, even
/// though Firestore rules already block them from writing any data.
const List<String> kWebAdminRoles = ['Admin', 'Super Admin', 'Analyst'];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local services only (Hive, SharedPreferences)
  bool hasSeenOnboarding = false;
  bool hasAcceptedLegalTerms = false;

  if (!kIsWeb) {
    try {
      await Hive.initFlutter();
      Hive.registerAdapter(StakeholderAdapter());

      // Initialize cache service
      final cacheService = StakeholderCacheService();
      await cacheService.initialize();

      // Check if the onboarding has been seen and legal terms accepted
      SharedPreferences prefs = await SharedPreferences.getInstance();
      hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;
      hasAcceptedLegalTerms = prefs.getBool('acceptedLegalTerms') ?? false;
    } catch (e) {
      debugPrint('Error initializing local services: $e');
    }
  } else {
    // Web platform - just get onboarding status
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;
      hasAcceptedLegalTerms = prefs.getBool('acceptedLegalTerms') ?? false;
    } catch (e) {
      debugPrint('Error getting onboarding status: $e');
    }
  }

  runApp(MyApp(
    hasSeenOnboarding: hasSeenOnboarding,
    hasAcceptedLegalTerms: hasAcceptedLegalTerms,
  ));
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  final bool hasAcceptedLegalTerms;
  const MyApp({
    super.key,
    this.hasSeenOnboarding = false,
    this.hasAcceptedLegalTerms = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
      // Platform-specific routing
      home: kIsWeb
          ? const WebAuthWrapper()
          : SplashScreen(
              hasSeenOnboarding: hasSeenOnboarding,
              hasAcceptedLegalTerms: hasAcceptedLegalTerms,
            ),
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

        // If user is logged in, verify their role before granting
        // access to the admin dashboard.
        if (snapshot.hasData) {
          return _WebRoleGate(uid: snapshot.data!.uid);
        }

        // Otherwise, show login screen
        return const AuthScreen();
      },
    );
  }
}

/// Confirms the signed-in user has an admin-capable role before showing
/// [WebAdminDashboard]. Users without one (e.g. the default 'User' role
/// given to mobile-app signups) are signed out and shown an explanation
/// instead of the admin UI.
class _WebRoleGate extends StatelessWidget {
  final String uid;
  const _WebRoleGate({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data?.data()?['role'] as String?;
        if (snapshot.hasError || !kWebAdminRoles.contains(role)) {
          return const _AccessDeniedScreen();
        }

        return const WebAdminDashboard();
      },
    );
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'This account does not have access to the web admin dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Sign out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
