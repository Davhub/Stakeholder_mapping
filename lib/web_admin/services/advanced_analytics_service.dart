import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:risdi/web_admin/models/analytics_models.dart';

/// Advanced analytics service for comprehensive data analysis
class AdvancedAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _stakeholdersCollection = 'stakeholders';
  static const String _activityEventsCollection = 'activity_events';

  /// Get stakeholder growth analysis (returns growth data points)
  Future<List<GrowthDataPoint>> getStakeholderGrowthAnalysis({
    required DateTime startDate,
    required DateTime endDate,
    String? state,
  }) async {
    try {
      // Fetch stakeholders created in period
      Query<Map<String, dynamic>> query = _firestore
              .collection(_stakeholdersCollection)
              .where('createdAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('createdAt',
                  isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          as Query<Map<String, dynamic>>;

      if (state != null && state.isNotEmpty) {
        query = query.where('state', isEqualTo: state)
            as Query<Map<String, dynamic>>;
      }

      final snapshot = await query.get();

      // Calculate growth by week
      final growthData = <GrowthDataPoint>[];
      final dailyCreations = <DateTime, int>{};

      for (var doc in snapshot.docs) {
        final createdAt = (doc['createdAt'] as Timestamp).toDate();
        final dateKey =
            DateTime(createdAt.year, createdAt.month, createdAt.day);
        dailyCreations[dateKey] = (dailyCreations[dateKey] ?? 0) + 1;
      }

      // Convert to daily growth points
      var currentDate = startDate;
      var cumulativeTotal = 0;

      while (currentDate.isBefore(endDate)) {
        final count = dailyCreations[currentDate] ?? 0;
        cumulativeTotal += count;
        final percentChange = cumulativeTotal > 0 && count > 0
            ? ((count / cumulativeTotal) * 100)
            : 0.0;

        growthData.add(GrowthDataPoint(
          date: currentDate,
          value: count,
          previousValue: cumulativeTotal - count,
          changePercentage: percentChange,
        ));

        currentDate = currentDate.add(const Duration(days: 1));
      }

      return growthData;
    } catch (e) {
      print('Error getting stakeholder growth: $e');
      return [];
    }
  }

  /// Get geographic distribution analysis
  Future<List<GeographicDistribution>> getGeographicDistribution({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_stakeholdersCollection)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final distribution = <String, Map<String, int>>{};

      for (var doc in snapshot.docs) {
        final state = doc['state'] as String?;
        final lga = doc['lga'] as String?;
        final ward = doc['ward'] as String?;

        if (state != null) {
          distribution.putIfAbsent(state, () => {});
          distribution[state]!['total'] =
              (distribution[state]!['total'] ?? 0) + 1;

          if (lga != null) {
            distribution[state]!['lga_$lga'] =
                (distribution[state]!['lga_$lga'] ?? 0) + 1;

            if (ward != null) {
              distribution[state]!['ward_$ward'] =
                  (distribution[state]!['ward_$ward'] ?? 0) + 1;
            }
          }
        }
      }

      // Convert to GeographicDistribution objects
      final geoDistributions = distribution.entries
          .map((entry) => GeographicDistribution(
                state: entry.key,
                stakeholderCount: entry.value['total'] ?? 0,
                percentage:
                    (((entry.value['total'] ?? 0) / snapshot.docs.length) * 100)
                        .toDouble(),
              ))
          .toList();

      return geoDistributions;
    } catch (e) {
      print('Error getting geographic distribution: $e');
      return [];
    }
  }

  /// Get comparative analytics (compare two periods)
  Future<ComparativeAnalytics?> getComparativeAnalytics({
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
  }) async {
    try {
      // Get metrics for period 1
      final period1Snapshot = await _firestore
          .collection(_stakeholdersCollection)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(period1Start))
          .where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(period1End))
          .get();

      // Get metrics for period 2
      final period2Snapshot = await _firestore
          .collection(_stakeholdersCollection)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(period2Start))
          .where('createdAt',
              isLessThanOrEqualTo: Timestamp.fromDate(period2End))
          .get();

      final period1Count = period1Snapshot.docs.length;
      final period2Count = period2Snapshot.docs.length;

      return ComparativeAnalytics.calculate(
        metric: 'Stakeholder Count',
        current: period2Count,
        previous: period1Count,
      );
    } catch (e) {
      print('Error getting comparative analytics: $e');
      return null;
    }
  }

  /// Get feature usage analysis
  Future<List<FeatureUsage>> getFeatureUsageAnalysis({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_activityEventsCollection)
          .where('eventType', isEqualTo: 'feature.used')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final featureUsage = <String, int>{};
      for (var doc in snapshot.docs) {
        final featureName = doc['featureName'] as String?;
        if (featureName != null) {
          featureUsage[featureName] = (featureUsage[featureName] ?? 0) + 1;
        }
      }

      // Sort by usage
      final sortedFeatures = featureUsage.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final usageData = sortedFeatures
          .map((e) => FeatureUsage(
                featureName: e.key,
                usageCount: e.value,
                uniqueUsers: 1, // Would need additional aggregation
                avgUsagePerUser: e.value.toDouble(),
              ))
          .toList();

      return usageData;
    } catch (e) {
      print('Error getting feature usage: $e');
      return [];
    }
  }

  /// Get user activity summary
  Future<AppUsageMetrics> getUserActivitySummary({
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

      return AppUsageMetrics(
        date: date,
        dailyActiveUsers: uniqueUsers.length,
        monthlyActiveUsers: uniqueUsers.length,
        totalSessions: usersSnapshot.docs.length,
        avgSessionDuration: 30.0,
        mostUsedFeatures: featureUsage,
        dropOffPoints: [],
      );
    } catch (e) {
      print('Error getting user activity summary: $e');
      return AppUsageMetrics(
        date: date,
        dailyActiveUsers: 0,
        monthlyActiveUsers: 0,
        totalSessions: 0,
        avgSessionDuration: 0,
        mostUsedFeatures: {},
        dropOffPoints: [],
      );
    }
  }

  /// Get system health metrics
  Future<Map<String, dynamic>> getSystemHealthMetrics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Error rate
      final errorsSnapshot = await _firestore
          .collection(_activityEventsCollection)
          .where('eventType', isEqualTo: 'error.occurred')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      // Total events
      final totalSnapshot = await _firestore
          .collection(_activityEventsCollection)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .count()
          .get();

      final errorRate = (totalSnapshot.count ?? 0) > 0
          ? (errorsSnapshot.docs.length / (totalSnapshot.count ?? 1)) * 100
          : 0.0;

      return {
        'totalEvents': totalSnapshot.count ?? 0,
        'errorCount': errorsSnapshot.docs.length,
        'errorRate': errorRate,
        'systemHealthScore': 100 - errorRate.clamp(0, 100),
      };
    } catch (e) {
      print('Error getting system health: $e');
      return {
        'totalEvents': 0,
        'errorCount': 0,
        'errorRate': 0.0,
        'systemHealthScore': 100.0,
      };
    }
  }

  /// Export analytics report
  Future<GeneratedReport?> exportAnalyticsReport({
    required String reportName,
    required ExportFormat format,
  }) async {
    try {
      final generatedReport = GeneratedReport(
        id: _firestore.collection('generated_reports').doc().id,
        reportId: _firestore.collection('reports').doc().id,
        reportName: reportName,
        format: format,
        requestedAt: DateTime.now(),
        requestedBy: _auth.currentUser?.email ?? 'system',
        status: ReportStatus.generating,
      );

      // Save to Firestore
      await _firestore
          .collection('generated_reports')
          .doc(generatedReport.id)
          .set(generatedReport.toFirestore());

      return generatedReport;
    } catch (e) {
      print('Error exporting report: $e');
      return null;
    }
  }

  /// Get stakeholder demographic insights
  Future<Map<String, dynamic>> getDemographicInsights({
    required DateTime startDate,
    required DateTime endDate,
    String? state,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
              .collection(_stakeholdersCollection)
              .where('createdAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
              .where('createdAt',
                  isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          as Query<Map<String, dynamic>>;

      if (state != null && state.isNotEmpty) {
        query = query.where('state', isEqualTo: state)
            as Query<Map<String, dynamic>>;
      }

      final snapshot = await query.get();

      final demographics = <String, dynamic>{
        'totalStakeholders': snapshot.docs.length,
        'categories': <String, int>{},
        'roles': <String, int>{},
        'states': <String, int>{},
      };

      for (var doc in snapshot.docs) {
        // Category
        final category = doc['category'] as String?;
        if (category != null) {
          demographics['categories'][category] =
              ((demographics['categories'][category] as int?) ?? 0) + 1;
        }

        // Role
        final role = doc['role'] as String?;
        if (role != null) {
          demographics['roles'][role] =
              ((demographics['roles'][role] as int?) ?? 0) + 1;
        }

        // State
        final docState = doc['state'] as String?;
        if (docState != null) {
          demographics['states'][docState] =
              ((demographics['states'][docState] as int?) ?? 0) + 1;
        }
      }

      return demographics;
    } catch (e) {
      print('Error getting demographic insights: $e');
      return {};
    }
  }

  /// Get trend analysis (time series data)
  Future<List<GrowthDataPoint>> getTrendAnalysis({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_stakeholdersCollection)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final dailyData = <DateTime, int>{};
      for (var doc in snapshot.docs) {
        final createdAt = (doc['createdAt'] as Timestamp).toDate();
        final dateKey =
            DateTime(createdAt.year, createdAt.month, createdAt.day);
        dailyData[dateKey] = (dailyData[dateKey] ?? 0) + 1;
      }

      final trendPoints = <GrowthDataPoint>[];
      var currentDate = startDate;
      var cumulativeTotal = 0;

      while (currentDate.isBefore(endDate)) {
        final count = dailyData[currentDate] ?? 0;
        cumulativeTotal += count;
        trendPoints.add(GrowthDataPoint(
          date: currentDate,
          value: count,
          previousValue: cumulativeTotal - count,
          changePercentage: 0,
        ));
        currentDate = currentDate.add(const Duration(days: 1));
      }

      return trendPoints;
    } catch (e) {
      print('Error getting trend analysis: $e');
      return [];
    }
  }
}
