import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:risdi/web_admin/services/admin_firestore_service.dart';

class WebProfileScreen extends StatefulWidget {
  const WebProfileScreen({Key? key}) : super(key: key);

  @override
  State<WebProfileScreen> createState() => _WebProfileScreenState();
}

class _WebProfileScreenState extends State<WebProfileScreen> {
  final AdminFirestoreService _service = AdminFirestoreService();
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      final profile = await _service.getAdminProfile();
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_currentUser == null || _userProfile == null) {
      return const Center(
        child: Text('Unable to load profile'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 32),

          // Profile Card
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.deepPurple.shade100,
                  child: Text(
                    (_currentUser!.email?[0] ?? 'A').toUpperCase(),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Email
                _buildInfoRow(
                  icon: Icons.email_rounded,
                  label: 'Email',
                  value: _currentUser!.email ?? 'N/A',
                ),
                const Divider(height: 32),

                // State
                _buildInfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Assigned State',
                  value: _userProfile!['state']?.toString() ?? 'N/A',
                ),
                const Divider(height: 32),

                // Role
                _buildInfoRow(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Role',
                  value: _userProfile!['role']?.toString() ?? 'N/A',
                ),
                const Divider(height: 32),

                // UID
                _buildInfoRow(
                  icon: Icons.fingerprint_rounded,
                  label: 'User ID',
                  value: _currentUser!.uid,
                ),
                const Divider(height: 32),

                // Account Creation
                _buildInfoRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Account Created',
                  value: _currentUser!.metadata.creationTime != null
                      ? _formatDateTime(_currentUser!.metadata.creationTime!)
                      : 'N/A',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading:
                      const Icon(Icons.lock_reset_rounded, color: Colors.blue),
                  title: const Text('Change Password'),
                  subtitle: const Text('Update your account password'),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _showChangePasswordDialog,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.build_circle_outlined,
                      color: Colors.orange),
                  title: const Text('Fix Missing Timestamps'),
                  subtitle: const Text(
                    'One-time repair for older stakeholder records missing '
                    'a creation date (affects Recent Additions and trends)',
                  ),
                  trailing:
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: _showBackfillTimestampsDialog,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.deepPurple, size: 24),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  void _showBackfillTimestampsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.build_circle_outlined, color: Colors.orange),
            SizedBox(width: 12),
            Text('Fix Missing Timestamps'),
          ],
        ),
        content: const Text(
          'This scans stakeholder records in your state and stamps a '
          "creation date on any that are missing one, using today's date "
          "as an approximation (the original add date can't be recovered). "
          'Records that already have a creation date are left untouched. '
          'This only affects your assigned state and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _runBackfillTimestamps();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Run Fix'),
          ),
        ],
      ),
    );
  }

  Future<void> _runBackfillTimestamps() async {
    final state = _userProfile?['state']?.toString();
    if (state == null || state.isEmpty || state == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not determine your assigned state'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Expanded(child: Text('Fixing missing timestamps...')),
          ],
        ),
      ),
    );

    try {
      final count = await _service.backfillMissingTimestamps(state);
      if (!mounted) return;
      Navigator.pop(context); // close progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count == 0
              ? 'No records needed fixing - all stakeholders already have a creation date'
              : 'Fixed $count stakeholder record(s)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close progress dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fixing timestamps: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: Colors.deepPurple),
            SizedBox(width: 12),
            Text('Change Password'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_rounded),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.lock_rounded),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                // TODO: Implement password change
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password change feature coming soon'),
                    backgroundColor: Colors.blue,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }
}
