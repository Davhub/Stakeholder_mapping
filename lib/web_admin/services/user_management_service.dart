import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:impact_konnect/firebase_options.dart';

/// Roles a Super Admin can assign from the web dashboard.
const List<String> kAssignableRoles = [
  'User',
  'Admin',
  'Analyst',
  'Super Admin',
];

/// A user account as shown in the web admin's user-management screen.
class ManagedUser {
  final String uid;
  final String email;
  final String role;
  final String state;
  final bool active;
  final String organizationId;
  final DateTime? createdAt;

  ManagedUser({
    required this.uid,
    required this.email,
    required this.role,
    required this.state,
    required this.active,
    required this.organizationId,
    this.createdAt,
  });

  factory ManagedUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawRole = data['role'];
    final rawState = data['state'] ?? data['State'];
    final rawCreatedAt = data['createdAt'];
    final rawOrgId = data['organizationId'];
    return ManagedUser(
      uid: doc.id,
      email: (data['email'] as String?)?.trim() ?? '',
      role: (rawRole is String && rawRole.trim().isNotEmpty)
          ? rawRole.trim()
          : 'User',
      state: (rawState is String) ? rawState.trim() : '',
      // Legacy documents predate this field; absent means active.
      active: data['active'] is bool ? data['active'] as bool : true,
      organizationId: (rawOrgId is String) ? rawOrgId.trim() : '',
      createdAt: rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null,
    );
  }
}

/// Result of attempting to provision one account.
class ProvisionResult {
  final bool success;
  final String message;
  const ProvisionResult(this.success, this.message);
}

/// Super Admin user administration: list accounts, provision new ones,
/// assign roles, and enable/disable access.
///
/// Account creation runs through a **secondary** Firebase app. Calling
/// `createUserWithEmailAndPassword` on the default instance immediately
/// signs the new account in, which would silently kick the Super Admin out
/// of their own dashboard mid-task. A throwaway secondary app keeps the
/// caller's session untouched.
class UserManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// The signed-in Super Admin's own organizationId. User management is
  /// always scoped to this - a Super Admin manages their own
  /// organization's people, never another organization's.
  Future<String?> _myOrganizationId() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _users.doc(uid).get();
    final orgId = doc.data()?['organizationId'];
    return (orgId is String && orgId.trim().isNotEmpty) ? orgId.trim() : null;
  }

  /// Live list of this admin's own organization's user accounts, sorted by
  /// email. Deliberately does *not* return every user on the platform -
  /// that would leak one organization's staff list to another.
  Stream<List<ManagedUser>> streamUsers() {
    return Stream.fromFuture(_myOrganizationId()).asyncExpand((orgId) {
      if (orgId == null) {
        debugPrint('streamUsers: no organizationId on the caller; '
            'returning an empty list rather than every user on the platform.');
        return Stream.value(<ManagedUser>[]);
      }
      return _users
          .where('organizationId', isEqualTo: orgId)
          .snapshots()
          .map((snap) {
        final users = snap.docs.map(ManagedUser.fromDoc).toList();
        users.sort(
            (a, b) => a.email.toLowerCase().compareTo(b.email.toLowerCase()));
        return users;
      });
    });
  }

  /// Creates an auth account plus its profile document, tagged with the
  /// creating admin's own organizationId so every account is traceable to
  /// the organization that provisioned it.
  Future<ProvisionResult> createUser({
    required String email,
    required String password,
    required String role,
    required String state,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return const ProvisionResult(false, 'Email is required.');
    }
    if (password.length < 6) {
      return const ProvisionResult(
          false, 'Password must be at least 6 characters.');
    }
    if (!kAssignableRoles.contains(role)) {
      return ProvisionResult(false, 'Unknown role "$role".');
    }

    final organizationId = await _myOrganizationId();
    if (organizationId == null) {
      return const ProvisionResult(false,
          'Your own account has no organization set, so a new user '
          'cannot be assigned one either. Contact the platform owner.');
    }

    FirebaseApp? secondaryApp;
    try {
      // Unique name so repeated invocations never collide with a
      // still-tearing-down instance.
      final appName = 'userProvisioner_${DateTime.now().microsecondsSinceEpoch}';
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      final newUid = credential.user!.uid;

      // Written through the *default* Firestore instance so the write runs
      // as the Super Admin, who is the one authorised to set roles.
      // Note: no password is ever stored here - Firebase Auth already
      // holds it, salted and hashed.
      await _users.doc(newUid).set({
        'email': trimmedEmail,
        'role': role,
        'state': state.trim(),
        'active': true,
        'organizationId': organizationId,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.email ?? 'unknown',
      });

      await secondaryAuth.signOut();
      return ProvisionResult(true, 'Created $trimmedEmail as $role.');
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'email-already-in-use' => 'That email already has an account.',
        'invalid-email' => 'That email address is not valid.',
        'weak-password' => 'Password is too weak.',
        _ => e.message ?? 'Could not create the account.',
      };
      return ProvisionResult(false, msg);
    } catch (e) {
      debugPrint('createUser failed: $e');
      return ProvisionResult(false, 'Could not create the account: $e');
    } finally {
      // Always tear the throwaway app down, even on failure, so a retry
      // isn't blocked by a lingering instance.
      await secondaryApp?.delete();
    }
  }

  Future<ProvisionResult> updateRole(String uid, String role) async {
    if (!kAssignableRoles.contains(role)) {
      return ProvisionResult(false, 'Unknown role "$role".');
    }
    try {
      await _users.doc(uid).update({'role': role});
      return ProvisionResult(true, 'Role updated to $role.');
    } catch (e) {
      debugPrint('updateRole failed: $e');
      return ProvisionResult(false, 'Could not update role: $e');
    }
  }

  Future<ProvisionResult> updateState(String uid, String state) async {
    try {
      await _users.doc(uid).update({'state': state.trim()});
      return ProvisionResult(true, 'State updated to $state.');
    } catch (e) {
      debugPrint('updateState failed: $e');
      return ProvisionResult(false, 'Could not update state: $e');
    }
  }

  /// Enables or disables sign-in for an account.
  ///
  /// This is the meaningful way to revoke access from the client: the
  /// Firebase client SDK cannot delete or disable *another* user's auth
  /// account (that needs the Admin SDK in a Cloud Function), so the app's
  /// login flow checks this flag and refuses disabled accounts.
  Future<ProvisionResult> setActive(String uid, bool active) async {
    try {
      await _users.doc(uid).update({'active': active});
      return ProvisionResult(
          true, active ? 'Account re-enabled.' : 'Account disabled.');
    } catch (e) {
      debugPrint('setActive failed: $e');
      return ProvisionResult(false, 'Could not update account: $e');
    }
  }

  /// Removes the profile document.
  ///
  /// Caveat worth knowing: the underlying Firebase Auth account survives,
  /// because deleting someone else's auth record requires the Admin SDK.
  /// Prefer [setActive] to revoke access.
  Future<ProvisionResult> deleteUserProfile(String uid) async {
    try {
      await _users.doc(uid).delete();
      return const ProvisionResult(true, 'Profile deleted.');
    } catch (e) {
      debugPrint('deleteUserProfile failed: $e');
      return ProvisionResult(false, 'Could not delete profile: $e');
    }
  }
}
