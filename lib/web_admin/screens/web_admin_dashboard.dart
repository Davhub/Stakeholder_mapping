import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:impact_konnect/web_admin/screens/web_dashboard_home.dart';
import 'package:impact_konnect/web_admin/screens/web_stakeholders_table.dart';
import 'package:impact_konnect/web_admin/screens/web_analytics_screen.dart';
import 'package:impact_konnect/web_admin/screens/web_profile_screen.dart';
import 'package:impact_konnect/web_admin/screens/web_users_screen.dart';
import 'package:impact_konnect/web_admin/services/admin_firestore_service.dart';
import 'package:impact_konnect/component/auth_form.dart';
/// Main Web Admin Dashboard with responsive sidebar layout
class WebAdminDashboard extends StatefulWidget {
  const WebAdminDashboard({Key? key}) : super(key: key);

  @override
  State<WebAdminDashboard> createState() => _WebAdminDashboardState();
}

class _WebAdminDashboardState extends State<WebAdminDashboard> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;

  final AdminFirestoreService _adminService = AdminFirestoreService();

  /// Whether the signed-in account may administer other users. Starts
  /// false so the Users tab is never briefly visible to a non-Super-Admin
  /// while the role is still loading.
  bool _canManageUsers = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final profile = await _adminService.getAdminProfile();
      final role = profile?['role'];
      if (mounted && role is String && role.trim() == 'Super Admin') {
        setState(() => _canManageUsers = true);
      }
    } catch (e) {
      debugPrint('Could not resolve dashboard permissions: $e');
    }
  }

  List<_NavigationItem> get _navigationItems => [
        _NavigationItem(
          icon: Icons.dashboard_rounded,
          label: 'Dashboard',
          route: '/dashboard',
          builder: () => const WebDashboardHome(),
        ),
        _NavigationItem(
          icon: Icons.people_rounded,
          label: 'Stakeholders',
          route: '/stakeholders',
          builder: () => const WebStakeholdersTable(),
        ),
        _NavigationItem(
          icon: Icons.analytics_rounded,
          label: 'Analytics',
          route: '/analytics',
          builder: () => const WebAnalyticsScreen(),
        ),
        // User administration is Super Admin only. Firestore rules enforce
        // this server-side too; hiding the tab just avoids showing an
        // Analyst a screen that would only ever error.
        if (_canManageUsers)
          _NavigationItem(
            icon: Icons.manage_accounts_rounded,
            label: 'Users',
            route: '/users',
            builder: () => const WebUsersScreen(),
          ),
        _NavigationItem(
          icon: Icons.person_rounded,
          label: 'Profile',
          route: '/profile',
          builder: () => const WebProfileScreen(),
        ),
      ];

  Widget _getScreen(int index) {
    final items = _navigationItems;
    if (index < 0 || index >= items.length) {
      return const WebDashboardHome();
    }
    return items[index].builder();
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.deepPurple),
            SizedBox(width: 12),
            Text('Logout Confirmation'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 1024;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(isSmallScreen),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                _buildTopBar(),

                // Content
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: _getScreen(_selectedIndex),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isSmallScreen) {
    if (isSmallScreen && !_isSidebarExpanded) {
      return const SizedBox.shrink();
    }

    final sidebarWidth = _isSidebarExpanded ? 250.0 : 80.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: sidebarWidth,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade700,
            Colors.deepPurple.shade500,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo/Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 20),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                            if (_isSidebarExpanded) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleLogout,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      if (_isSidebarExpanded) ...[
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                _isSidebarExpanded ? Icons.menu_open : Icons.menu,
                color: Colors.deepPurple,
              ),
              onPressed: () {
                setState(() {
                  _isSidebarExpanded = !_isSidebarExpanded;
                });
              },
              tooltip: 'Toggle Sidebar',
            ),
            const SizedBox(width: 16),
            Text(
              _navigationItems[_selectedIndex].label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            // User info
            FutureBuilder<User?>(
              future: Future.value(FirebaseAuth.instance.currentUser),
              builder: (context, snapshot) {
                final email = snapshot.data?.email ?? 'Admin';
                return Row(
                  children: [
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        email[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  /// Each item owns the screen it shows. Keeping them together means a
  /// conditionally-hidden tab (e.g. Super-Admin-only Users) can't shift a
  /// separate switch statement out of alignment.
  final Widget Function() builder;

  _NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.builder,
  });
}
