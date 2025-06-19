import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mapping/firebase_options.dart';
import 'package:mapping/model/stakeholder_contact_model.dart';
import 'package:mapping/screens/screen.dart';
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

  // Initialize Hive and register the adapter
  await Hive.initFlutter();
  Hive.registerAdapter(StakeholderAdapter());

  // Open a Hive box to store the stakeholders
  await Hive.openBox<Stakeholder>('stakeholderBox');

  // Check if the onboarding has been seen
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasSeenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // Show SplashScreen, then OnboardingScreen if first launch, or Dashboard
      home: SplashScreen(hasSeenOnboarding: hasSeenOnboarding),
    );
  }
}
