import 'package:cloud_firestore/cloud_firestore.dart';

/// Role model with permissions
class Role {
  final String id;
  final String name;
  final String description;
  final List<String> permissions;
  final bool isActive;
  final bool isSystemRole; // Cannot be deleted
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  Role({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    this.isActive = true,
    this.isSystemRole = false,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
  });

  factory Role.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Role(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      permissions: List<String>.from(data['permissions'] ?? []),
      isActive: data['isActive'] ?? true,
      isSystemRole: data['isSystemRole'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'permissions': permissions,
      'isActive': isActive,
      'isSystemRole': isSystemRole,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
    };
  }
}

/// Permission categories
class PermissionCategory {
  static const String stakeholders = 'stakeholders';
  static const String users = 'users';
  static const String analytics = 'analytics';
  static const String auditLogs = 'auditLogs';
  static const String roles = 'roles';
  static const String reports = 'reports';
}

/// Available permissions
class Permissions {
  // Stakeholder permissions
  static const String viewStakeholders = 'stakeholders.view';
  static const String createStakeholders = 'stakeholders.create';
  static const String editStakeholders = 'stakeholders.edit';
  static const String deleteStakeholders = 'stakeholders.delete';
  static const String exportStakeholders = 'stakeholders.export';

  // User management permissions
  static const String viewUsers = 'users.view';
  static const String createUsers = 'users.create';
  static const String editUsers = 'users.edit';
  static const String deactivateUsers = 'users.deactivate';

  // Role management permissions
  static const String viewRoles = 'roles.view';
  static const String createRoles = 'roles.create';
  static const String editRoles = 'roles.edit';
  static const String deleteRoles = 'roles.delete';

  // Analytics permissions
  static const String viewAnalytics = 'analytics.view';
  static const String exportAnalytics = 'analytics.export';
  static const String viewAdvancedAnalytics = 'analytics.advanced';

  // Audit log permissions
  static const String viewAuditLogs = 'auditLogs.view';
  static const String exportAuditLogs = 'auditLogs.export';

  // Report permissions
  static const String viewReports = 'reports.view';
  static const String createReports = 'reports.create';
  static const String exportReports = 'reports.export';

  static List<PermissionDefinition> getAllPermissions() {
    return [
      // Stakeholder permissions
      PermissionDefinition(
        id: viewStakeholders,
        name: 'View Stakeholders',
        category: PermissionCategory.stakeholders,
        description: 'View stakeholder list and details',
      ),
      PermissionDefinition(
        id: createStakeholders,
        name: 'Create Stakeholders',
        category: PermissionCategory.stakeholders,
        description: 'Add new stakeholders',
      ),
      PermissionDefinition(
        id: editStakeholders,
        name: 'Edit Stakeholders',
        category: PermissionCategory.stakeholders,
        description: 'Modify stakeholder information',
      ),
      PermissionDefinition(
        id: deleteStakeholders,
        name: 'Delete Stakeholders',
        category: PermissionCategory.stakeholders,
        description: 'Remove stakeholders',
      ),
      PermissionDefinition(
        id: exportStakeholders,
        name: 'Export Stakeholders',
        category: PermissionCategory.stakeholders,
        description: 'Export stakeholder data',
      ),

      // User permissions
      PermissionDefinition(
        id: viewUsers,
        name: 'View Users',
        category: PermissionCategory.users,
        description: 'View user accounts',
      ),
      PermissionDefinition(
        id: createUsers,
        name: 'Create Users',
        category: PermissionCategory.users,
        description: 'Create new user accounts',
      ),
      PermissionDefinition(
        id: editUsers,
        name: 'Edit Users',
        category: PermissionCategory.users,
        description: 'Modify user information',
      ),
      PermissionDefinition(
        id: deactivateUsers,
        name: 'Deactivate Users',
        category: PermissionCategory.users,
        description: 'Deactivate user accounts',
      ),

      // Role permissions
      PermissionDefinition(
        id: viewRoles,
        name: 'View Roles',
        category: PermissionCategory.roles,
        description: 'View role definitions',
      ),
      PermissionDefinition(
        id: createRoles,
        name: 'Create Roles',
        category: PermissionCategory.roles,
        description: 'Create new roles',
      ),
      PermissionDefinition(
        id: editRoles,
        name: 'Edit Roles',
        category: PermissionCategory.roles,
        description: 'Modify role permissions',
      ),
      PermissionDefinition(
        id: deleteRoles,
        name: 'Delete Roles',
        category: PermissionCategory.roles,
        description: 'Delete custom roles',
      ),

      // Analytics permissions
      PermissionDefinition(
        id: viewAnalytics,
        name: 'View Analytics',
        category: PermissionCategory.analytics,
        description: 'View basic analytics',
      ),
      PermissionDefinition(
        id: viewAdvancedAnalytics,
        name: 'Advanced Analytics',
        category: PermissionCategory.analytics,
        description: 'Access advanced analytics features',
      ),
      PermissionDefinition(
        id: exportAnalytics,
        name: 'Export Analytics',
        category: PermissionCategory.analytics,
        description: 'Export analytics data',
      ),

      // Audit log permissions
      PermissionDefinition(
        id: viewAuditLogs,
        name: 'View Audit Logs',
        category: PermissionCategory.auditLogs,
        description: 'View audit trail',
      ),
      PermissionDefinition(
        id: exportAuditLogs,
        name: 'Export Audit Logs',
        category: PermissionCategory.auditLogs,
        description: 'Export audit logs',
      ),

      // Report permissions
      PermissionDefinition(
        id: viewReports,
        name: 'View Reports',
        category: PermissionCategory.reports,
        description: 'View generated reports',
      ),
      PermissionDefinition(
        id: createReports,
        name: 'Create Reports',
        category: PermissionCategory.reports,
        description: 'Generate custom reports',
      ),
      PermissionDefinition(
        id: exportReports,
        name: 'Export Reports',
        category: PermissionCategory.reports,
        description: 'Export report data',
      ),
    ];
  }

  static Map<String, List<PermissionDefinition>> getPermissionsByCategory() {
    final permissions = getAllPermissions();
    final Map<String, List<PermissionDefinition>> grouped = {};

    for (var perm in permissions) {
      if (!grouped.containsKey(perm.category)) {
        grouped[perm.category] = [];
      }
      grouped[perm.category]!.add(perm);
    }

    return grouped;
  }
}

class PermissionDefinition {
  final String id;
  final String name;
  final String category;
  final String description;

  PermissionDefinition({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
  });
}

/// Extended user model with role
class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String roleId;
  final String state;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? createdBy;

  AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    required this.roleId,
    required this.state,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
    this.createdBy,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      roleId: data['roleId'] ?? data['role'] ?? '',
      state: data['state'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'roleId': roleId,
      'state': state,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'createdBy': createdBy,
    };
  }
}
