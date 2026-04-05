import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:risdi/web_admin/models/audit_models.dart';

/// Immutable audit logging service
/// All operations are append-only for compliance and security
class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _auditLogsCollection = 'audit_logs';
  static const String _usersCollection = 'users';

  /// Log an action (append-only operation)
  Future<bool> logAction({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
    String platform = 'web',
    String? ipAddress,
    Map<String, dynamic>? changes,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Fetch user role
      final userDoc =
          await _firestore.collection(_usersCollection).doc(user.uid).get();
      final userRole = userDoc.data()?['roleId'] ?? 'unknown';

      final auditLog = AuditLog(
        id: _firestore.collection(_auditLogsCollection).doc().id,
        userId: user.uid,
        userEmail: user.email ?? 'unknown',
        userRole: userRole,
        action: action,
        entityType: entityType,
        entityId: entityId,
        metadata: metadata,
        platform: platform,
        timestamp: DateTime.now(),
        ipAddress: ipAddress,
        changes: changes,
      );

      // Append to audit logs (immutable)
      await _firestore
          .collection(_auditLogsCollection)
          .doc(auditLog.id)
          .set(auditLog.toFirestore());

      return true;
    } catch (e) {
      print('Error logging action: $e');
      return false;
    }
  }

  /// Log stakeholder action
  Future<bool> logStakeholderAction({
    required String action,
    required String stakeholderId,
    Map<String, dynamic>? changes,
  }) async {
    return logAction(
      action: action,
      entityType: AuditEntity.stakeholder,
      entityId: stakeholderId,
      changes: changes,
    );
  }

  /// Log user action
  Future<bool> logUserAction({
    required String action,
    required String targetUserId,
    Map<String, dynamic>? metadata,
  }) async {
    return logAction(
      action: action,
      entityType: AuditEntity.user,
      entityId: targetUserId,
      metadata: metadata,
    );
  }

  /// Log authentication action
  Future<bool> logAuthAction({
    required String action,
    bool success = true,
  }) async {
    return logAction(
      action: action,
      entityType: AuditEntity.session,
      metadata: {'success': success},
    );
  }

  /// Get audit logs with filtering and pagination
  Future<PaginatedAuditLogs> getAuditLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? userRole,
    String? action,
    String? entityType,
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection(_auditLogsCollection)
          .orderBy('timestamp', descending: true);

      // Apply filters
      if (startDate != null) {
        query = query.where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            as Query<Map<String, dynamic>>;
      }

      if (endDate != null) {
        query = query.where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            as Query<Map<String, dynamic>>;
      }

      if (userId != null && userId.isNotEmpty) {
        query = query.where('userId', isEqualTo: userId)
            as Query<Map<String, dynamic>>;
      }

      if (userRole != null && userRole.isNotEmpty) {
        query = query.where('userRole', isEqualTo: userRole)
            as Query<Map<String, dynamic>>;
      }

      if (action != null && action.isNotEmpty) {
        query = query.where('action', isEqualTo: action)
            as Query<Map<String, dynamic>>;
      }

      if (entityType != null && entityType.isNotEmpty) {
        query = query.where('entityType', isEqualTo: entityType)
            as Query<Map<String, dynamic>>;
      }

      if (startAfter != null) {
        query =
            query.startAfterDocument(startAfter) as Query<Map<String, dynamic>>;
      }

      final snapshot = await query.limit(limit + 1).get();

      final logs = snapshot.docs
          .take(limit)
          .map((doc) => AuditLog.fromFirestore(doc))
          .toList();

      final hasMore = snapshot.docs.length > limit;
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return PaginatedAuditLogs(
        logs: logs,
        hasMore: hasMore,
        lastDocument: lastDoc,
        total: snapshot.docs.length,
      );
    } catch (e) {
      print('Error fetching audit logs: $e');
      return PaginatedAuditLogs(logs: [], hasMore: false);
    }
  }

  /// Search audit logs by text
  Future<List<AuditLog>> searchAuditLogs({
    required String query,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var q = _firestore
          .collection(_auditLogsCollection)
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        q = q.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        q = q.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await q.limit(limit).get();

      final searchLower = query.toLowerCase();
      return snapshot.docs
          .map((doc) => AuditLog.fromFirestore(doc))
          .where((log) =>
              log.userEmail.toLowerCase().contains(searchLower) ||
              log.action.toLowerCase().contains(searchLower) ||
              log.entityType.toLowerCase().contains(searchLower) ||
              (log.entityId?.toLowerCase().contains(searchLower) ?? false))
          .toList();
    } catch (e) {
      print('Error searching audit logs: $e');
      return [];
    }
  }

  /// Get action summary (grouped by action type)
  Future<Map<String, int>> getActionSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection(_auditLogsCollection);

      if (startDate != null) {
        query = query.where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            as Query<Map<String, dynamic>>;
      }

      if (endDate != null) {
        query = query.where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            as Query<Map<String, dynamic>>;
      }

      final snapshot = await query.get();

      final summary = <String, int>{};
      for (var doc in snapshot.docs) {
        final action = doc['action'] as String;
        summary[action] = (summary[action] ?? 0) + 1;
      }

      return summary;
    } catch (e) {
      print('Error getting action summary: $e');
      return {};
    }
  }

  /// Get user activity summary
  Future<Map<String, int>> getUserActivitySummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection(_auditLogsCollection);

      if (startDate != null) {
        query = query.where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            as Query<Map<String, dynamic>>;
      }

      if (endDate != null) {
        query = query.where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            as Query<Map<String, dynamic>>;
      }

      final snapshot = await query.get();

      final summary = <String, int>{};
      for (var doc in snapshot.docs) {
        final userId = doc['userId'] as String;
        summary[userId] = (summary[userId] ?? 0) + 1;
      }

      return summary;
    } catch (e) {
      print('Error getting user activity summary: $e');
      return {};
    }
  }

  /// Export audit logs (immutable reference to original data)
  Future<List<Map<String, dynamic>>?> exportAuditLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
    String? action,
    int limit = 10000,
  }) async {
    try {
      final auditLogs = await getAuditLogs(
        startDate: startDate,
        endDate: endDate,
        userId: userId,
        action: action,
        limit: limit,
      );

      return auditLogs.logs
          .map((log) => {
                'id': log.id,
                'timestamp': log.timestamp.toIso8601String(),
                'userId': log.userId,
                'userEmail': log.userEmail,
                'userRole': log.userRole,
                'action': log.action,
                'entityType': log.entityType,
                'entityId': log.entityId,
                'platform': log.platform,
                'changes': log.changes,
              })
          .toList();
    } catch (e) {
      print('Error exporting audit logs: $e');
      return null;
    }
  }

  /// Get audit logs count
  Future<int> getAuditLogsCount({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection(_auditLogsCollection);

      if (startDate != null) {
        query = query.where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
            as Query<Map<String, dynamic>>;
      }

      if (endDate != null) {
        query = query.where('timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate))
            as Query<Map<String, dynamic>>;
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error counting audit logs: $e');
      return 0;
    }
  }
}

/// Paginated audit logs result
class PaginatedAuditLogs {
  final List<AuditLog> logs;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final int total;

  PaginatedAuditLogs({
    required this.logs,
    required this.hasMore,
    this.lastDocument,
    this.total = 0,
  });
}
