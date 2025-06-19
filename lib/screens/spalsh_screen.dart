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
          // Navigate to User's DashboardScreen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const DashboardScreen(),
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
    return const Scaffold(
      backgroundColor: const Color(0xffe9f7fc),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Text(
            'Know Your Stakeholders - South West',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
            ),
          ),
        ),
      ),
    );
  }
}
