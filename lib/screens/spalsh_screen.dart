import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:risdi/firebase_options.dart';
import 'package:risdi/component/component.dart';
import 'package:risdi/screens/screen.dart';
import 'package:risdi/component/auth_form.dart';
import 'package:risdi/screens/admin_dashboard_screen.dart';
import 'package:risdi/screens/home_screen_with_navbar.dart'; // User dashboard // Auth/Login screen

class SplashScreen extends StatefulWidget {
  final bool hasSeenOnboarding;
  final bool hasAcceptedLegalTerms;
  const SplashScreen({
    Key? key,
    required this.hasSeenOnboarding,
    required this.hasAcceptedLegalTerms,
  }) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Initialize Firebase during the splash delay
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Firebase initialized successfully');
      }
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
      // Firebase might already be initialized via native platform, continue anyway
    }

    await Future.delayed(const Duration(seconds: 5)); // Splash delay

    // Now Firebase should be initialized, check current user
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (e) {
      debugPrint('Error accessing FirebaseAuth: $e');
      // Give it one more try after a short delay
      await Future.delayed(const Duration(seconds: 1));
      try {
        user = FirebaseAuth.instance.currentUser;
      } catch (e2) {
        debugPrint('Second attempt to access FirebaseAuth failed: $e2');
      }
    }

    if (user != null) {
      // If user is logged in, fetch role from Firestore
      if (mounted) {
        _checkUserRole(user);
      }
      return;
    }

    if (!mounted) return;

    if (!widget.hasSeenOnboarding) {
      // First launch: show onboarding, which leads into legal acceptance.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    } else if (!widget.hasAcceptedLegalTerms) {
      // Onboarding was seen previously but legal terms were never accepted
      // (e.g. app was closed mid-flow) - block further progress until they are.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LegalAcceptanceScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  Future<void> _checkUserRole(User user) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users') // Assumes 'users' collection stores user roles
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (userDoc.exists) {
        String role = userDoc['role']; // Fetch role field from Firestore

        if (role == 'Admin') {
          // Navigate to AdminDashboardScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AdminDashboardScreen(),
            ),
          );
        } else {
          // Navigate to User's HomeScreen (new main screen)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreenWithNavbar(),
            ),
          );
        }
      } else {
        // Handle case where role is not found (fallback to AuthScreen)
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AuthScreen()),
          );
        }
      }
    } catch (e) {
      // Handle Firestore errors (e.g., network issues)
      debugPrint('Error fetching user role: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white24, // Background color for splash
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/1.png', width: 240, height: 240),
                          const SizedBox(height: 20),
                          const Text(
                            'RISDi',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f6ed4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

