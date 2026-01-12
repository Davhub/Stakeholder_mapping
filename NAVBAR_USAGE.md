# Custom Navigation Bar Usage Guide

The `CustomNavBar` component is a reusable navigation bar that provides consistent navigation throughout the Stakeholder Mapping application.

## Features

- **4 Main Navigation Items:**
  - Home (index 0) - Main dashboard with recent stakeholders
  - Directory (index 1) - Browse all stakeholders  
  - Favourites (index 2) - Saved stakeholders
  - Profile (index 3) - User account and settings

- **Smooth Animations:** Fade transitions between screens
- **Active State Indicators:** Visual feedback for current screen
- **Consistent Design:** Follows app design system

## Usage Methods

### Method 1: Direct Scaffold Integration

```dart
import 'package:flutter/material.dart';
import 'package:mapping/component/custom_navbar.dart';

class YourScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YourContent(),
      bottomNavigationBar: const CustomNavBar(currentIndex: 0), // Set appropriate index
    );
  }
}
```

### Method 2: Using ScreenWithNavBar Wrapper

```dart
import 'package:flutter/material.dart';
import 'package:mapping/component/custom_navbar.dart';

class YourScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ScreenWithNavBar(
      currentIndex: 0, // Set appropriate index
      child: YourContent(),
    );
  }
}
```

### Method 3: Using NavBarMixin (For StatefulWidgets)

```dart
import 'package:flutter/material.dart';
import 'package:mapping/component/custom_navbar.dart';

class YourScreen extends StatefulWidget {
  @override
  State<YourScreen> createState() => _YourScreenState();
}

class _YourScreenState extends State<YourScreen> with NavBarMixin {
  @override
  Widget build(BuildContext context) {
    return buildWithNavBar(
      body: YourContent(),
      navIndex: 0, // Set appropriate index
    );
  }
}
```

## Navigation Index Reference

- **0:** Home Screen (`HomeScreen`)
- **1:** Directory Screen (`DashboardScreen`) 
- **2:** Favourites Screen (`FavouriteScreen`)
- **3:** Profile Screen (`ProfileScreen`)

## Example Implementations

### Complete Home Screen with Navbar

```dart
import 'package:flutter/material.dart';
import 'package:mapping/component/custom_navbar.dart';
import 'package:mapping/screens/screen.dart';

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
```

### Complete Directory Screen with Navbar

```dart
import 'package:flutter/material.dart';
import 'package:mapping/component/custom_navbar.dart';
import 'package:mapping/screens/screen.dart';

class DirectoryScreenWithNavbar extends StatelessWidget {
  const DirectoryScreenWithNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const DashboardScreen(),
      bottomNavigationBar: const CustomNavBar(currentIndex: 1),
    );
  }
}
```

## Integration Notes

1. **Screen Updates:** Each screen should set its correct `currentIndex` to highlight the active tab
2. **Navigation:** The navbar automatically handles navigation between screens
3. **Consistency:** Use the same navbar across all main app screens
4. **Customization:** The navbar can be extended with additional items if needed

## File Locations

- **Component:** `lib/component/custom_navbar.dart`
- **Screens:** `lib/screens/screen.dart` (exports all screens)
- **Usage Examples:** See individual screen implementations

## Future Enhancements

The navbar is designed to be extensible for:
- Badge notifications
- Dynamic tab hiding/showing
- Route-based navigation
- Theme customization
