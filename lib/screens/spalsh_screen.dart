import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:mapping/component/component.dart';
import 'package:mapping/screens/screen.dart'; // User dashboard // Auth/Login screen

class SplashScreen extends StatefulWidget {
  final bool hasSeenOnboarding;
  const SplashScreen({Key? key, required this.hasSeenOnboarding})
      : super(key: key);

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
    await Future.delayed(const Duration(seconds: 5)); // Splash delay

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // If user is logged in, fetch role from Firestore
      _checkUserRole(user);
    } else if (widget.hasSeenOnboarding) {
      // If no user but onboarding is complete, navigate to AuthScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    } else {
      // If onboarding is not complete, navigate to AuthScreen or Onboarding
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    } catch (e) {
      // Handle Firestore errors (e.g., network issues)
      print('Error fetching user role: $e');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade500,
              Colors.blue.shade300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo Container
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 1500),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.people_alt_rounded,
                              size: 70,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  
                  // App Title with Fade Animation
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 2000),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Column(
                          children: [
                            const Text(
                              'Know Your Stakeholders',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'South West Region',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 60),
                  
                  // Loading Indicator
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Loading your workspace...',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
