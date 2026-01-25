import 'package:cloud_firestore/cloud_firestore.dart';

/// Advanced analytics report configuration
class AnalyticsReport {
  final String id;
  final String name;
  final String description;
  final ReportType type;
  final DateRange dateRange;
  final List<String> metrics;
  final Map<String, dynamic>? filters;
  final String createdBy;
  final DateTime createdAt;
  final String? schedule; // cron expression for scheduled reports

  AnalyticsReport({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.dateRange,
    required this.metrics,
    this.filters,
    required this.createdBy,
    required this.createdAt,
    this.schedule,
  });

  factory AnalyticsReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnalyticsReport(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: ReportType.values.firstWhere(
        (e) => e.toString() == 'ReportType.${data['type']}',
        orElse: () => ReportType.stakeholderGrowth,
      ),
      dateRange: DateRange.fromMap(data['dateRange'] as Map<String, dynamic>),
      metrics: List<String>.from(data['metrics'] ?? []),
      filters: data['filters'] as Map<String, dynamic>?,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      schedule: data['schedule'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'dateRange': dateRange.toMap(),
      'metrics': metrics,
      'filters': filters,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'schedule': schedule,
    };
  }
}

enum ReportType {
  stakeholderGrowth,
  geographicDistribution,
  userActivity,
  comparativeAnalysis,
  custom,
}

class DateRange {
  final DateTime startDate;
  final DateTime endDate;
  final DateRangePreset? preset;

  DateRange({
    required this.startDate,
    required this.endDate,
    this.preset,
  });

  factory DateRange.fromMap(Map<String, dynamic> map) {
    return DateRange(
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      preset: map['preset'] != null
          ? DateRangePreset.values.firstWhere(
              (e) => e.toString() == 'DateRangePreset.${map['preset']}',
              orElse: () => DateRangePreset.custom,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'preset': preset?.toString().split('.').last,
    };
  }

  factory DateRange.today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return DateRange(
      startDate: start,
      endDate: now,
      preset: DateRangePreset.today,
    );
  }

  factory DateRange.last7Days() {
    final now = DateTime.now();
    return DateRange(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
      preset: DateRangePreset.last7Days,
    );
  }

  factory DateRange.last30Days() {
    final now = DateTime.now();
    return DateRange(
      startDate: now.subtract(const Duration(days: 30)),
      endDate: now,
      preset: DateRangePreset.last30Days,
    );
  }

  factory DateRange.thisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return DateRange(
      startDate: start,
      endDate: now,
      preset: DateRangePreset.thisMonth,
    );
  }

  factory DateRange.lastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = DateTime(now.year, now.month, 0);
    return DateRange(
      startDate: lastMonth,
      endDate: endOfLastMonth,
      preset: DateRangePreset.lastMonth,
    );
  }
}

enum DateRangePreset {
  today,
  yesterday,
  last7Days,
  last30Days,
  thisMonth,
  lastMonth,
  thisYear,
  custom,
}

/// Growth trend data point
class GrowthDataPoint {
  final DateTime date;
  final int value;
  final int? previousValue;
  final double? changePercentage;

  GrowthDataPoint({
    required this.date,
    required this.value,
    this.previousValue,
    this.changePercentage,
  });

  factory GrowthDataPoint.fromMap(Map<String, dynamic> map) {
    return GrowthDataPoint(
      date: (map['date'] as Timestamp).toDate(),
      value: map['value'] ?? 0,
      previousValue: map['previousValue'],
      changePercentage: map['changePercentage']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'value': value,
      'previousValue': previousValue,
      'changePercentage': changePercentage,
    };
  }
}

/// Geographic distribution data
class GeographicDistribution {
  final String state;
  final String? lga;
  final String? ward;
  final int stakeholderCount;
  final double percentage;
  final Map<String, int>? subDistribution;

  GeographicDistribution({
    required this.state,
    this.lga,
    this.ward,
    required this.stakeholderCount,
    required this.percentage,
    this.subDistribution,
  });
}

/// User activity summary
class UserActivitySummary {
  final int totalUsers;
  final int activeUsers;
  final int newUsers;
  final double avgSessionDuration;
  final Map<String, int> activityByRole;
  final Map<String, int> activityByState;

  UserActivitySummary({
    required this.totalUsers,
    required this.activeUsers,
    required this.newUsers,
    required this.avgSessionDuration,
    required this.activityByRole,
    required this.activityByState,
  });
}

/// Comparative analytics (current vs previous period)
class ComparativeAnalytics {
  final String metric;
  final int currentValue;
  final int previousValue;
  final double changePercentage;
  final bool isPositive;

  ComparativeAnalytics({
    required this.metric,
    required this.currentValue,
    required this.previousValue,
    required this.changePercentage,
    required this.isPositive,
  });

  factory ComparativeAnalytics.calculate({
    required String metric,
    required int current,
    required int previous,
  }) {
    final change = previous > 0 ? ((current - previous) / previous * 100) : 0.0;
    return ComparativeAnalytics(
      metric: metric,
      currentValue: current,
      previousValue: previous,
      changePercentage: change,
      isPositive: change >= 0,
    );
  }
}

/// Feature usage statistics
class FeatureUsage {
  final String featureName;
  final int usageCount;
  final int uniqueUsers;
  final double avgUsagePerUser;

  FeatureUsage({
    required this.featureName,
    required this.usageCount,
    required this.uniqueUsers,
    required this.avgUsagePerUser,
  });
}

/// App usage metrics
class AppUsageMetrics {
  final DateTime date;
  final int dailyActiveUsers;
  final int monthlyActiveUsers;
  final int totalSessions;
  final double avgSessionDuration;
  final Map<String, int> mostUsedFeatures;
  final List<String> dropOffPoints;

  AppUsageMetrics({
    required this.date,
    required this.dailyActiveUsers,
    required this.monthlyActiveUsers,
    required this.totalSessions,
    required this.avgSessionDuration,
    required this.mostUsedFeatures,
    required this.dropOffPoints,
  });
}

/// Export format options
enum ExportFormat {
  csv,
  excel,
  pdf,
  json,
}

/// Report generation status
enum ReportStatus {
  pending,
  generating,
  completed,
  failed,
}

class GeneratedReport {
  final String id;
  final String reportId;
  final String reportName;
  final ReportStatus status;
  final DateTime requestedAt;
  final DateTime? completedAt;
  final String requestedBy;
  final ExportFormat format;
  final String? downloadUrl;
  final String? errorMessage;
  final int? recordCount;

  GeneratedReport({
    required this.id,
    required this.reportId,
    required this.reportName,
    required this.status,
    required this.requestedAt,
    this.completedAt,
    required this.requestedBy,
    required this.format,
    this.downloadUrl,
    this.errorMessage,
    this.recordCount,
  });

  factory GeneratedReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GeneratedReport(
      id: doc.id,
      reportId: data['reportId'] ?? '',
      reportName: data['reportName'] ?? '',
      status: ReportStatus.values.firstWhere(
        (e) => e.toString() == 'ReportStatus.${data['status']}',
        orElse: () => ReportStatus.pending,
      ),
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      requestedBy: data['requestedBy'] ?? '',
      format: ExportFormat.values.firstWhere(
        (e) => e.toString() == 'ExportFormat.${data['format']}',
        orElse: () => ExportFormat.csv,
      ),
      downloadUrl: data['downloadUrl'],
      errorMessage: data['errorMessage'],
      recordCount: data['recordCount'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reportId': reportId,
      'reportName': reportName,
      'status': status.toString().split('.').last,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'requestedBy': requestedBy,
      'format': format.toString().split('.').last,
      'downloadUrl': downloadUrl,
      'errorMessage': errorMessage,
      'recordCount': recordCount,
    };
  }
}
