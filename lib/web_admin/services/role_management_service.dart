import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:risdi/web_admin/models/role_models.dart';

/// Role management service - handles CRUD operations for roles
class RoleManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _rolesCollection = 'roles';
  static const String _usersCollection = 'users';

  /// Get all active roles
  Future<List<Role>> getAllRoles() async {
    try {
      final snapshot = await _firestore
          .collection(_rolesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => Role.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching roles: $e');
      return [];
    }
  }

  /// Get role by ID
  Future<Role?> getRoleById(String roleId) async {
    try {
      final doc =
          await _firestore.collection(_rolesCollection).doc(roleId).get();
      if (!doc.exists) return null;
      return Role.fromFirestore(doc);
    } catch (e) {
      print('Error fetching role: $e');
      return null;
    }
  }

  /// Get all permissions for a role
  Future<List<String>> getRolePermissions(String roleId) async {
    try {
      final role = await getRoleById(roleId);
      return role?.permissions ?? [];
    } catch (e) {
      print('Error fetching role permissions: $e');
      return [];
    }
  }

  /// Create a new role (Super Admin only)
  Future<String?> createRole({
    required String name,
    required String description,
    required List<String> permissions,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final role = Role(
        id: _firestore.collection(_rolesCollection).doc().id,
        name: name,
        description: description,
        permissions: permissions,
        isActive: true,
        isSystemRole: false,
        createdAt: DateTime.now(),
        createdBy: user.uid,
      );

      await _firestore
          .collection(_rolesCollection)
          .doc(role.id)
          .set(role.toFirestore());

      return role.id;
    } catch (e) {
      print('Error creating role: $e');
      return null;
    }
  }

  /// Update role permissions
  Future<bool> updateRole({
    required String roleId,
    String? name,
    String? description,
    List<String>? permissions,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (permissions != null) updates['permissions'] = permissions;
      if (isActive != null) updates['isActive'] = isActive;

      updates['updatedAt'] = Timestamp.now();

      await _firestore.collection(_rolesCollection).doc(roleId).update(updates);
      return true;
    } catch (e) {
      print('Error updating role: $e');
      return false;
    }
  }

  /// Deactivate a role (mark as inactive instead of deleting)
  Future<bool> deactivateRole(String roleId) async {
    try {
      final role = await getRoleById(roleId);
      if (role?.isSystemRole ?? false) {
        print('Cannot deactivate system roles');
        return false;
      }

      await _firestore.collection(_rolesCollection).doc(roleId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error deactivating role: $e');
      return false;
    }
  }

  /// Check if user has a specific permission
  Future<bool> userHasPermission(
    String userId,
    String permissionId,
  ) async {
    try {
      final userDoc =
          await _firestore.collection(_usersCollection).doc(userId).get();
      if (!userDoc.exists) return false;

      final roleId = userDoc.data()?['roleId'] as String?;
      if (roleId == null) return false;

      final permissions = await getRolePermissions(roleId);
      return permissions.contains(permissionId);
    } catch (e) {
      print('Error checking permission: $e');
      return false;
    }
  }

  /// Get current user's permissions
  Future<List<String>> getCurrentUserPermissions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final userDoc =
          await _firestore.collection(_usersCollection).doc(user.uid).get();
      if (!userDoc.exists) return [];

      final roleId = userDoc.data()?['roleId'] as String?;
      if (roleId == null) return [];

      return await getRolePermissions(roleId);
    } catch (e) {
      print('Error fetching current user permissions: $e');
      return [];
    }
  }

  /// Get all users with a specific role
  Future<List<AppUser>> getUsersByRole(String roleId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .where('roleId', isEqualTo: roleId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching users by role: $e');
      return [];
    }
  }

  /// Create default system roles (call once during setup)
  Future<void> createDefaultRoles() async {
    try {
      // Check if roles already exist
      final existing = await _firestore
          .collection(_rolesCollection)
          .where('isSystemRole', isEqualTo: true)
          .get();

      if (existing.docs.isNotEmpty) {
        print('Default roles already exist');
        return;
      }

      final user = _auth.currentUser;
      final createdBy = user?.uid ?? 'system';

      // Super Admin Role
      await _firestore.collection(_rolesCollection).doc('super_admin').set({
        'name': 'Super Admin',
        'description': 'Full system access',
        'permissions':
            Permissions.getAllPermissions().map((p) => p.id).toList(),
        'isActive': true,
        'isSystemRole': true,
        'createdAt': Timestamp.now(),
        'createdBy': createdBy,
      });

      // Admin Role
      await _firestore.collection(_rolesCollection).doc('admin').set({
        'name': 'Admin',
        'description': 'Administrative access within assigned state',
        'permissions': [
          Permissions.viewStakeholders,
          Permissions.createStakeholders,
          Permissions.editStakeholders,
          Permissions.deleteStakeholders,
          Permissions.exportStakeholders,
          Permissions.viewAnalytics,
          Permissions.exportAnalytics,
          Permissions.viewAuditLogs,
          Permissions.viewReports,
          Permissions.exportReports,
          Permissions.viewUsers,
        ],
        'isActive': true,
        'isSystemRole': true,
        'createdAt': Timestamp.now(),
        'createdBy': createdBy,
      });

      // Analyst Role
      await _firestore.collection(_rolesCollection).doc('analyst').set({
        'name': 'Analyst',
        'description': 'Analytics and reporting access',
        'permissions': [
          Permissions.viewStakeholders,
          Permissions.viewAnalytics,
          Permissions.exportAnalytics,
          Permissions.viewReports,
          Permissions.exportReports,
          Permissions.createReports,
        ],
        'isActive': true,
        'isSystemRole': true,
        'createdAt': Timestamp.now(),
        'createdBy': createdBy,
      });

      // Viewer Role
      await _firestore.collection(_rolesCollection).doc('viewer').set({
        'name': 'Viewer',
        'description': 'Read-only access',
        'permissions': [
          Permissions.viewStakeholders,
          Permissions.viewAnalytics,
          Permissions.viewReports,
        ],
        'isActive': true,
        'isSystemRole': true,
        'createdAt': Timestamp.now(),
        'createdBy': createdBy,
      });

      print('Default roles created successfully');
    } catch (e) {
      print('Error creating default roles: $e');
    }
  }
}
