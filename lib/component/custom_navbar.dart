import 'package:flutter/material.dart';
import 'package:mapping/screens/screen.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const CustomNavBar({
    Key? key,
    required this.currentIndex,
    this.onTap,
  }) : super(key: key);

  static const List<NavBarItem> _items = [
    NavBarItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      route: '/home',
    ),
    NavBarItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Directory',
      route: '/directory',
    ),
    NavBarItem(
      icon: Icons.favorite_outline,
      activeIcon: Icons.favorite,
      label: 'Favourites',
      route: '/favourites',
    ),
    NavBarItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isActive = currentIndex == index;

              return _NavBarButton(
                item: item,
                isActive: isActive,
                onTap: () {
                  if (onTap != null) {
                    onTap!(index);
                  } else {
                    _navigateToScreen(context, index);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  static void _navigateToScreen(BuildContext context, int index) {
    Widget screen;
    
    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const DashboardScreen();
        break;
      case 2:
        screen = const FavouriteScreen();
        break;
      case 3:
        screen = const ProfileScreen();
        break;
      default:
        screen = const HomeScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  // Static method to get current index based on screen type
  static int getCurrentIndex(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route?.settings.name != null) {
      switch (route!.settings.name) {
        case '/home':
          return 0;
        case '/directory':
          return 1;
        case '/favourites':
          return 2;
        case '/profile':
          return 3;
        default:
          return 0;
      }
    }
    
    // Fallback: detect by widget type
    final widget = context.widget;
    if (widget is HomeScreen) return 0;
    if (widget is DashboardScreen) return 1;
    if (widget is FavouriteScreen) return 2;
    if (widget is ProfileScreen) return 3;
    
    return 0;
  }
}

class _NavBarButton extends StatelessWidget {
  final NavBarItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarButton({
    Key? key,
    required this.item,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.blue : Colors.grey;
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                key: ValueKey(isActive),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: color,
                fontSize: isActive ? 12 : 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}

// Mixin to easily add navbar to screens
mixin NavBarMixin<T extends StatefulWidget> on State<T> {
  int currentNavIndex = 0;

  Widget buildWithNavBar({required Widget body, int? navIndex}) {
    return Scaffold(
      body: body,
      bottomNavigationBar: CustomNavBar(
        currentIndex: navIndex ?? currentNavIndex,
      ),
    );
  }
}

// Wrapper widget for screens that need navbar
class ScreenWithNavBar extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const ScreenWithNavBar({
    Key? key,
    required this.child,
    this.currentIndex = 0,
  }) : super(key: key);

  @override
  State<ScreenWithNavBar> createState() => _ScreenWithNavBarState();
}

class _ScreenWithNavBarState extends State<ScreenWithNavBar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: CustomNavBar(
        currentIndex: widget.currentIndex,
      ),
    );
  }
}
