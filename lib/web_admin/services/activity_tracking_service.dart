import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:risdi/web_admin/models/audit_models.dart';

/// Tracks user activity events and sessions for analytics
class ActivityTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _activityEventsCollection = 'activity_events';
  static const String _userSessionsCollection = 'user_sessions';

  /// Track a user activity event
  Future<bool> trackEvent({
    required String eventType,
    required String screenName,
    String? featureName,
    int? durationMs,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get or create session
      final sessionId = await _getOrCreateSession(user.uid);

      final activityEvent = ActivityEvent(
        id: _firestore.collection(_activityEventsCollection).doc().id,
        userId: user.uid,
        eventType: eventType,
        screenName: screenName,
        featureName: featureName,
        sessionId: sessionId,
        timestamp: DateTime.now(),
        duration: durationMs,
        platform: 'web',
        metadata: metadata,
      );

      await _firestore
          .collection(_activityEventsCollection)
          .doc(activityEvent.id)
          .set(activityEvent.toFirestore());

      // Update session
      await _updateSessionActivity(user.uid, sessionId, screenName);

      return true;
    } catch (e) {
      print('Error tracking event: $e');
      return false;
    }
  }

  /// Track screen navigation
  Future<bool> trackScreenView({
    required String screenName,
    Map<String, dynamic>? metadata,
  }) async {
    return trackEvent(
      eventType: ActivityEventType.screenView,
      screenName: screenName,
      metadata: metadata,
    );
  }

  /// Track feature usage
  Future<bool> trackFeatureUsage({
    required String featureName,
    required String screenName,
    int? durationMs,
    Map<String, dynamic>? metadata,
  }) async {
    return trackEvent(
      eventType: ActivityEventType.featureUsed,
      screenName: screenName,
      featureName: featureName,
      durationMs: durationMs,
      metadata: metadata,
    );
  }

  /// Track button click
  Future<bool> trackButtonClick({
    required String buttonName,
    required String screenName,
    Map<String, dynamic>? metadata,
  }) async {
    return trackEvent(
      eventType: 'button.clicked',
      screenName: screenName,
      featureName: buttonName,
      metadata: metadata,
    );
  }

  /// Track form submission
  Future<bool> trackFormSubmission({
    required String formName,
    required String screenName,
    bool success = true,
    Map<String, dynamic>? metadata,
  }) async {
    final eventMetadata = {
      ...?metadata,
      'success': success,
    };

    return trackEvent(
      eventType: 'form.submitted',
      screenName: screenName,
      featureName: formName,
      metadata: eventMetadata,
    );
  }

  /// Track error event
  Future<bool> trackError({
    required String errorType,
    required String screenName,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) async {
    final errorMetadata = {
      ...?metadata,
      'errorType': errorType,
      'errorMessage': errorMessage,
    };

    return trackEvent(
      eventType: ActivityEventType.errorOccurred,
      screenName: screenName,
      metadata: errorMetadata,
    );
  }

  /// Get user's recent activity
  Future<List<ActivityEvent>> getUserActivity({
    String? userId,
    int limit = 100,
  }) async {
    try {
      final targetUserId = userId ?? _auth.currentUser?.uid;
      if (targetUserId == null) return [];

      final snapshot = await _firestore
          .collection(_activityEventsCollection)
          .where('userId', isEqualTo: targetUserId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ActivityEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching user activity: $e');
      return [];
    }
  }

  /// Get activity by feature
  Future<List<ActivityEvent>> getFeatureActivity({
    required String featureName,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 500,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
              .collection(_activityEventsCollection)
              .where('featureName', isEqualTo: featureName)
              .orderBy('timestamp', descending: true)
          as Query<Map<String, dynamic>>;

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

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) => ActivityEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching feature activity: $e');
      return [];
    }
  }

  /// Get activity by screen
  Future<List<ActivityEvent>> getScreenActivity({
    required String screenName,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 500,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
              .collection(_activityEventsCollection)
              .where('screenName', isEqualTo: screenName)
              .orderBy('timestamp', descending: true)
          as Query<Map<String, dynamic>>;

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

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) => ActivityEvent.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching screen activity: $e');
      return [];
    }
  }

  /// Get feature usage summary
  Future<Map<String, int>> getFeatureUsageSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
              .collection(_activityEventsCollection)
              .where('eventType', isEqualTo: ActivityEventType.featureUsed)
          as Query<Map<String, dynamic>>;

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
        final featureName = doc['featureName'] as String?;
        if (featureName != null) {
          summary[featureName] = (summary[featureName] ?? 0) + 1;
        }
      }

      return summary;
    } catch (e) {
      print('Error getting feature usage summary: $e');
      return {};
    }
  }

  /// Get screen views summary
  Future<Map<String, int>> getScreenViewsSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
              .collection(_activityEventsCollection)
              .where('eventType', isEqualTo: ActivityEventType.screenView)
          as Query<Map<String, dynamic>>;

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
        final screenName = doc['screenName'] as String;
        summary[screenName] = (summary[screenName] ?? 0) + 1;
      }

      return summary;
    } catch (e) {
      print('Error getting screen views summary: $e');
      return {};
    }
  }

  /// Get user session
  Future<UserSession?> getUserSession({
    String? userId,
    String? sessionId,
  }) async {
    try {
      if (sessionId != null && sessionId.isNotEmpty) {
        final doc = await _firestore
            .collection(_userSessionsCollection)
            .doc(sessionId)
            .get();

        if (doc.exists) {
          return UserSession.fromFirestore(doc);
        }
      }

      // Get current session if no sessionId provided
      final targetUserId = userId ?? _auth.currentUser?.uid;
      if (targetUserId == null) return null;

      final snapshot = await _firestore
          .collection(_userSessionsCollection)
          .where('userId', isEqualTo: targetUserId)
          .where('isActive', isEqualTo: true)
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserSession.fromFirestore(snapshot.docs.first);
      }

      return null;
    } catch (e) {
      print('Error fetching user session: $e');
      return null;
    }
  }

  /// Get daily metrics
  Future<Map<String, dynamic>> getDailyMetrics({
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      // Count active users
      final usersSnapshot = await _firestore
          .collection(_activityEventsCollection)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      final uniqueUsers = <String>{};
      final featureUsage = <String, int>{};

      for (var doc in usersSnapshot.docs) {
        uniqueUsers.add(doc['userId']);
        final featureName = doc['featureName'] as String?;
        if (featureName != null) {
          featureUsage[featureName] = (featureUsage[featureName] ?? 0) + 1;
        }
      }

      return {
        'date': date.toIso8601String(),
        'dailyActiveUsers': uniqueUsers.length,
        'totalEvents': usersSnapshot.docs.length,
        'featureUsage': featureUsage,
      };
    } catch (e) {
      print('Error getting daily metrics: $e');
      return {};
    }
  }

  /// Export activity events
  Future<List<Map<String, dynamic>>?> exportActivityEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
    int limit = 10000,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
              .collection(_activityEventsCollection)
              .orderBy('timestamp', descending: true)
          as Query<Map<String, dynamic>>;

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

      if (eventType != null && eventType.isNotEmpty) {
        query = query.where('eventType', isEqualTo: eventType)
            as Query<Map<String, dynamic>>;
      }

      final snapshot = await query.limit(limit).get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                'userId': doc['userId'],
                'eventType': doc['eventType'],
                'screenName': doc['screenName'],
                'featureName': doc['featureName'],
                'timestamp':
                    (doc['timestamp'] as Timestamp).toDate().toIso8601String(),
                'duration': doc['duration'],
              })
          .toList();
    } catch (e) {
      print('Error exporting activity events: $e');
      return null;
    }
  }

  /// Helper: Get or create session
  Future<String> _getOrCreateSession(String userId) async {
    try {
      // Try to get active session
      final snapshot = await _firestore
          .collection(_userSessionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }

      // Create new session
      final sessionId = _firestore.collection(_userSessionsCollection).doc().id;
      final session = UserSession(
        id: sessionId,
        userId: userId,
        platform: 'web',
        startTime: DateTime.now(),
        endTime: null,
        screensVisited: [],
        eventCount: 0,
      );

      await _firestore
          .collection(_userSessionsCollection)
          .doc(sessionId)
          .set(session.toFirestore());

      return sessionId;
    } catch (e) {
      print('Error getting/creating session: $e');
      return '';
    }
  }

  /// Helper: Update session activity
  Future<void> _updateSessionActivity(
    String userId,
    String sessionId,
    String screenName,
  ) async {
    try {
      await _firestore
          .collection(_userSessionsCollection)
          .doc(sessionId)
          .update({
        'eventCount': FieldValue.increment(1),
        'screensVisited': FieldValue.arrayUnion([screenName]),
      });
    } catch (e) {
      print('Error updating session: $e');
    }
  }

  /// End user session
  Future<bool> endSession(String sessionId) async {
    try {
      await _firestore
          .collection(_userSessionsCollection)
          .doc(sessionId)
          .update({
        'endTime': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error ending session: $e');
      return false;
    }
  }
}

/// Note: Activity event types are defined in audit_models.dart as ActivityEventType
