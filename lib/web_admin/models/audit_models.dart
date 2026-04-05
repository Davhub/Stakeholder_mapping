import 'package:cloud_firestore/cloud_firestore.dart';

/// Audit log entry - immutable record of system actions
class AuditLog {
  final String id;
  final String userId;
  final String userEmail;
  final String userRole;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? metadata;
  final String platform; // 'web' or 'mobile'
  final DateTime timestamp;
  final String? ipAddress;
  final Map<String, dynamic>? changes; // before/after for updates

  AuditLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userRole,
    required this.action,
    required this.entityType,
    this.entityId,
    this.metadata,
    required this.platform,
    required this.timestamp,
    this.ipAddress,
    this.changes,
  });

  factory AuditLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userRole: data['userRole'] ?? '',
      action: data['action'] ?? '',
      entityType: data['entityType'] ?? '',
      entityId: data['entityId'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      platform: data['platform'] ?? 'web',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      ipAddress: data['ipAddress'],
      changes: data['changes'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userRole': userRole,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'metadata': metadata,
      'platform': platform,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'changes': changes,
    };
  }
}

/// Audit action types
class AuditAction {
  // Authentication
  static const String login = 'auth.login';
  static const String logout = 'auth.logout';
  static const String loginFailed = 'auth.login_failed';

  // Stakeholder actions
  static const String stakeholderCreated = 'stakeholder.created';
  static const String stakeholderUpdated = 'stakeholder.updated';
  static const String stakeholderDeleted = 'stakeholder.deleted';
  static const String stakeholderViewed = 'stakeholder.viewed';
  static const String stakeholderExported = 'stakeholder.exported';

  // User actions
  static const String userCreated = 'user.created';
  static const String userUpdated = 'user.updated';
  static const String userDeactivated = 'user.deactivated';
  static const String userActivated = 'user.activated';

  // Role actions
  static const String roleCreated = 'role.created';
  static const String roleUpdated = 'role.updated';
  static const String roleDeleted = 'role.deleted';

  // Report actions
  static const String reportGenerated = 'report.generated';
  static const String reportExported = 'report.exported';

  // System actions
  static const String settingsUpdated = 'system.settings_updated';
  static const String dataImported = 'system.data_imported';
}

/// Entity types for audit logs
class AuditEntity {
  static const String stakeholder = 'stakeholder';
  static const String user = 'user';
  static const String role = 'role';
  static const String report = 'report';
  static const String system = 'system';
  static const String session = 'session';
}

/// User activity tracking event
class ActivityEvent {
  final String id;
  final String userId;
  final String? userEmail;
  final String? roleId;
  final String eventType;
  final String? screenName;
  final String? featureName;
  final Map<String, dynamic>? metadata;
  final String platform;
  final DateTime timestamp;
  final String? sessionId;
  final int? duration; // in milliseconds

  ActivityEvent({
    required this.id,
    required this.userId,
    this.userEmail,
    this.roleId,
    required this.eventType,
    this.screenName,
    this.featureName,
    this.metadata,
    required this.platform,
    required this.timestamp,
    this.sessionId,
    this.duration,
  });

  factory ActivityEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityEvent(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'],
      roleId: data['roleId'],
      eventType: data['eventType'] ?? '',
      screenName: data['screenName'],
      featureName: data['featureName'],
      metadata: data['metadata'] as Map<String, dynamic>?,
      platform: data['platform'] ?? 'web',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      sessionId: data['sessionId'],
      duration: data['duration'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'roleId': roleId,
      'eventType': eventType,
      'screenName': screenName,
      'featureName': featureName,
      'metadata': metadata,
      'platform': platform,
      'timestamp': Timestamp.fromDate(timestamp),
      'sessionId': sessionId,
      'duration': duration,
    };
  }
}

/// Activity event types
class ActivityEventType {
  // Session events
  static const String sessionStart = 'session.start';
  static const String sessionEnd = 'session.end';

  // Navigation events
  static const String screenView = 'screen.view';
  static const String screenExit = 'screen.exit';

  // Feature usage
  static const String featureUsed = 'feature.used';
  static const String searchPerformed = 'search.performed';
  static const String filterApplied = 'filter.applied';
  static const String exportInitiated = 'export.initiated';

  // Errors
  static const String errorOccurred = 'error.occurred';
  static const String crashReported = 'crash.reported';
}

/// User session tracking
class UserSession {
  final String id;
  final String userId;
  final String platform;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration; // in milliseconds
  final List<String> screensVisited;
  final int eventCount;
  final Map<String, dynamic>? deviceInfo;

  UserSession({
    required this.id,
    required this.userId,
    required this.platform,
    required this.startTime,
    this.endTime,
    this.duration,
    this.screensVisited = const [],
    this.eventCount = 0,
    this.deviceInfo,
  });

  factory UserSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      platform: data['platform'] ?? 'web',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      duration: data['duration'],
      screensVisited: List<String>.from(data['screensVisited'] ?? []),
      eventCount: data['eventCount'] ?? 0,
      deviceInfo: data['deviceInfo'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'platform': platform,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'duration': duration,
      'screensVisited': screensVisited,
      'eventCount': eventCount,
      'deviceInfo': deviceInfo,
    };
  }
}

/// Analytics aggregation models
class DailyMetrics {
  final DateTime date;
  final int dailyActiveUsers;
  final int newStakeholders;
  final int totalSessions;
  final int avgSessionDuration;
  final Map<String, int> featureUsage;

  DailyMetrics({
    required this.date,
    required this.dailyActiveUsers,
    required this.newStakeholders,
    required this.totalSessions,
    required this.avgSessionDuration,
    required this.featureUsage,
  });

  factory DailyMetrics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyMetrics(
      date: (data['date'] as Timestamp).toDate(),
      dailyActiveUsers: data['dailyActiveUsers'] ?? 0,
      newStakeholders: data['newStakeholders'] ?? 0,
      totalSessions: data['totalSessions'] ?? 0,
      avgSessionDuration: data['avgSessionDuration'] ?? 0,
      featureUsage: Map<String, int>.from(data['featureUsage'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'dailyActiveUsers': dailyActiveUsers,
      'newStakeholders': newStakeholders,
      'totalSessions': totalSessions,
      'avgSessionDuration': avgSessionDuration,
      'featureUsage': featureUsage,
    };
  }
}
