import 'package:flutter/material.dart';
import 'package:impact_konnect/component/custom_navbar.dart';
import 'package:impact_konnect/screens/screen.dart';

class HomeScreenWithNavbar extends StatelessWidget {
  const HomeScreenWithNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const HomeScreen(),
      bottomNavigationBar: const CustomNavBar(currentIndex: 0),
    );
  }
}
