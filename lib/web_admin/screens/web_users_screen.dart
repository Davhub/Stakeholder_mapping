import 'package:flutter/material.dart';
import 'package:impact_konnect/web_admin/services/user_management_service.dart';

/// States the platform currently covers.
const List<String> kSelectableStates = [
  'Oyo',
  'Osun',
  'Ekiti',
  'Ogun',
  'Ondo',
  'Lagos',
];

/// Super Admin user administration screen: list accounts, provision new
/// ones, assign roles, and enable/disable access.
class WebUsersScreen extends StatefulWidget {
  const WebUsersScreen({super.key});

  @override
  State<WebUsersScreen> createState() => _WebUsersScreenState();
}

class _WebUsersScreenState extends State<WebUsersScreen> {
  final UserManagementService _service = UserManagementService();
  String _search = '';

  void _report(ProvisionResult result) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _openCreateUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String role = 'User';
    String state = kSelectableStates.first;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Create User Account'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [],
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Email is required';
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Temporary password',
                          helperText:
                              'Share this with the user; they can change it '
                              'later via Forgot Password.',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (v) {
                          if ((v ?? '').length < 6) {
                            return 'At least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: role,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: kAssignableRoles
                            .map((r) =>
                                DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => role = v ?? 'User'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: state,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          prefixIcon: Icon(Icons.map_outlined),
                        ),
                        items: kSelectableStates
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setDialogState(
                            () => state = v ?? kSelectableStates.first),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          setDialogState(() => submitting = true);
                          final result = await _service.createUser(
                            email: emailController.text,
                            password: passwordController.text,
                            role: role,
                            state: state,
                          );
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          _report(result);
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
    passwordController.dispose();
  }

  Future<void> _confirmDelete(ManagedUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
          'Delete the profile for ${user.email}?\n\n'
          'Their sign-in account itself cannot be removed from here, so '
          'disabling the account is usually the better way to revoke '
          'access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _report(await _service.deleteUserProfile(user.uid));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'User Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openCreateUserDialog,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Create User'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Create accounts, assign roles, and control who can sign in.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search by email or role...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<ManagedUser>>(
              stream: _service.streamUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Could not load users: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final all = snapshot.data ?? [];
                final users = _search.isEmpty
                    ? all
                    : all
                        .where((u) =>
                            u.email.toLowerCase().contains(_search) ||
                            u.role.toLowerCase().contains(_search))
                        .toList();

                if (users.isEmpty) {
                  return Center(
                    child: Text(
                      all.isEmpty
                          ? 'No user accounts yet.'
                          : 'No users match "$_search".',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) =>
                        _buildUserRow(users[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(ManagedUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                user.active ? Colors.blue.shade50 : Colors.grey.shade200,
            child: Text(
              user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
              style: TextStyle(
                color: user.active
                    ? Colors.blue.shade700
                    : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email.isEmpty ? '(no email)' : user.email,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  user.state.isEmpty ? 'No state set' : user.state,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          if (!user.active)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Disabled',
                style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              initialValue:
                  kAssignableRoles.contains(user.role) ? user.role : null,
              isDense: true,
              decoration: const InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              items: kAssignableRoles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) async {
                if (v == null || v == user.role) return;
                _report(await _service.updateRole(user.uid, v));
              },
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: user.active ? 'Disable sign-in' : 'Re-enable sign-in',
            child: IconButton(
              icon: Icon(
                user.active ? Icons.block : Icons.check_circle_outline,
                color: user.active ? Colors.orange : Colors.green,
              ),
              onPressed: () async {
                _report(await _service.setActive(user.uid, !user.active));
              },
            ),
          ),
          Tooltip(
            message: 'Delete profile',
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(user),
            ),
          ),
        ],
      ),
    );
  }
}
