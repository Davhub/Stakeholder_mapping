import 'package:flutter/material.dart';
import 'package:risdi/component/custom_navbar.dart';
import 'package:risdi/screens/screen.dart';

class DirectoryScreenWithNavbar extends StatelessWidget {
  const DirectoryScreenWithNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const StakeholderListScreen(),
      bottomNavigationBar: const CustomNavBar(currentIndex: 1),
    );
  }
}

class FavouriteScreenWithNavbar extends StatelessWidget {
  const FavouriteScreenWithNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const FavouriteScreen(),
      bottomNavigationBar: const CustomNavBar(currentIndex: 2),
    );
  }
}

class ProfileScreenWithNavbar extends StatelessWidget {
  const ProfileScreenWithNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const ProfileScreen(),
      bottomNavigationBar: const CustomNavBar(currentIndex: 3),
    );
  }
}
