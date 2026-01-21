import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mapping/firebase_options.dart';
import 'package:mapping/model/stakeholder_contact_model.dart';
import 'package:mapping/screens/screen.dart';
import 'package:mapping/web_admin/screens/web_admin_dashboard.dart';
import 'package:mapping/component/auth_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import for SharedPreferences

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Disable Firestore offline persistence
  // Enable Firestore logging
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true, // Enables offline persistence
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED, // Set cache size
  );

  FirebaseFirestore.instance.settings = const Settings(
    sslEnabled: true, // Maintain default SSL settings
    persistenceEnabled: true,
  );

  // Initialize Hive only for mobile platforms
  if (!kIsWeb) {
    await Hive.initFlutter();
    Hive.registerAdapter(StakeholderAdapter());
    await Hive.openBox<Stakeholder>('stakeholderBox');
  }

  // Check if the onboarding has been seen (only for mobile)
  bool hasSeenOnboarding = false;
  if (!kIsWeb) {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;
  }

  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stakeholder Mapping',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
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
