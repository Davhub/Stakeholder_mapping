import 'package:flutter/material.dart';
import 'package:mapping/component/custom_navbar.dart';

class TestNavbarScreen extends StatelessWidget {
  const TestNavbarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(
        child: Text(
          'Testing Navbar',
          style: TextStyle(fontSize: 24),
        ),
      ),
      bottomNavigationBar: const CustomNavBar(currentIndex: 0),
    );
  }
}
