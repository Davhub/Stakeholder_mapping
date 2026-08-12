import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:impact_konnect/component/component.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:impact_konnect/core/constants/legal_content.dart';
import 'package:impact_konnect/screens/legal_document_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String appVersion = '';
  String buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        appVersion = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      debugPrint('Error loading app version: $e');
    }
  }

  Future<void> _loadUserData() async {
    try {
      user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>?;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmAndDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This permanently deletes your account and profile data. '
          'This cannot be undone. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final password = await _promptForPassword();
    if (password == null || !mounted) return;

    await _deleteAccount(password);
  }

  Future<String?> _promptForPassword() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Your Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Password'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(String password) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.email == null) return;

    try {
      // Deleting an account is a sensitive operation that Firebase requires
      // a *recent* sign-in for, so re-authenticate before proceeding.
      final credential = EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );
      await currentUser.reauthenticateWithCredential(credential);

      final uid = currentUser.uid;
      final firestore = FirebaseFirestore.instance;

      // Remove this user's personal data: their favorites and profile doc.
      // Stakeholder directory records are organizational program data, not
      // this user's personal data, so they are intentionally left intact.
      final favorites = await firestore
          .collection('favorites')
          .where('userId', isEqualTo: uid)
          .get();
      final batch = firestore.batch();
      for (final doc in favorites.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(firestore.collection('users').doc(uid));
      await batch.commit();

      await currentUser.delete();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = e.code == 'wrong-password' || e.code == 'invalid-credential'
          ? 'Incorrect password. Please try again.'
          : 'Error deleting account: ${e.message}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle
            Text(
              "Manage your account and preferences",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.email ?? 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userData?['role'] ?? 'User',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  if (userData?['state'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${userData!['state']} State',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Information
            const Text(
              "Account Information",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              icon: Icons.email_outlined,
              title: "Email Address",
              value: user?.email ?? 'Not available',
              color: Colors.blue,
            ),
            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.verified_user_outlined,
              title: "Email Verified",
              value: user?.emailVerified == true ? 'Verified' : 'Not Verified',
              color: user?.emailVerified == true ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.location_on_outlined,
              title: "State",
              value: userData?['state'] ?? 'Not specified',
              color: Colors.purple,
            ),
            const SizedBox(height: 12),

            _buildInfoCard(
              icon: Icons.admin_panel_settings_outlined,
              title: "Role",
              value: userData?['role'] ?? 'User',
              color: Colors.indigo,
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildActionCard(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              subtitle: "How we handle your data",
              color: Colors.blue,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LegalDocumentScreen(
                      title: kPrivacyPolicyTitle,
                      body: kPrivacyPolicyText,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildActionCard(
              icon: Icons.description_outlined,
              title: "Terms & Conditions",
              subtitle: "Rules for using Impact Konnect",
              color: Colors.deepPurple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LegalDocumentScreen(
                      title: kTermsAndConditionsTitle,
                      body: kTermsAndConditionsText,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildActionCard(
              icon: Icons.help_outline,
              title: "Help & Support",
              subtitle: "Get help and contact support",
              color: Colors.teal,
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'olatunjioladotun3@gmail.com',
                  queryParameters: {
                    'subject': 'Help & Support - Impact Konnect App',
                    'body': 'Hi,\n\nI need help with the Impact Konnect app.\n\nPlease describe your issue below:\n\n---\n\nApp Version: $appVersion\nBuild: $buildNumber',
                  },
                );
                try {
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open email client. Please contact: olatunjioladotun3@gmail.com'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 12),

            _buildActionCard(
              icon: Icons.logout,
              title: "Sign Out",
              subtitle: "Sign out of your account",
              color: Colors.red,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _logout();
                        },
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            _buildActionCard(
              icon: Icons.delete_forever_outlined,
              title: "Delete Account",
              subtitle: "Permanently delete your account and data",
              color: Colors.red,
              onTap: _confirmAndDeleteAccount,
            ),
            const SizedBox(height: 24),

            // App Version Info
            Center(
              child: Column(
                children: [
                  Text(
                    'App Version',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appVersion.isNotEmpty ? 'v$appVersion' : 'Loading...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Build: $buildNumber',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              radius: 20,
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
