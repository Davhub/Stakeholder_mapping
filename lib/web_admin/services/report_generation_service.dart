import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:risdi/web_admin/models/analytics_models.dart';

/// Report generation and management service
class ReportGenerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _reportsCollection = 'reports';
  static const String _generatedReportsCollection = 'generated_reports';
  static const String _reportSchedulesCollection = 'report_schedules';

  /// Create a new report
  Future<String?> createReport({
    required String name,
    required String description,
    required ReportType type,
    required DateRange dateRange,
    required List<String> metrics,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final reportId = _firestore.collection(_reportsCollection).doc().id;

      final report = AnalyticsReport(
        id: reportId,
        name: name,
        description: description,
        type: type,
        dateRange: dateRange,
        metrics: metrics,
        filters: filters,
        createdBy: _auth.currentUser?.email ?? 'system',
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .set(report.toFirestore());

      return reportId;
    } catch (e) {
      print('Error creating report: $e');
      return null;
    }
  }

  /// Get report by ID
  Future<AnalyticsReport?> getReport(String reportId) async {
    try {
      final doc =
          await _firestore.collection(_reportsCollection).doc(reportId).get();

      if (!doc.exists) return null;

      return AnalyticsReport.fromFirestore(doc);
    } catch (e) {
      print('Error fetching report: $e');
      return null;
    }
  }

  /// Get all reports
  Future<List<AnalyticsReport>> getAllReports({
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_reportsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AnalyticsReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching reports: $e');
      return [];
    }
  }

  /// Get reports by type
  Future<List<AnalyticsReport>> getReportsByType({
    required ReportType type,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_reportsCollection)
          .where('type', isEqualTo: type.toString().split('.').last)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AnalyticsReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching reports by type: $e');
      return [];
    }
  }

  /// Get reports by date range
  Future<List<AnalyticsReport>> getReportsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_reportsCollection)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => AnalyticsReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching reports by date range: $e');
      return [];
    }
  }

  /// Update report
  Future<bool> updateReport({
    required String reportId,
    required String name,
    required String description,
    required List<String> metrics,
    Map<String, dynamic>? filters,
  }) async {
    try {
      await _firestore.collection(_reportsCollection).doc(reportId).update({
        'name': name,
        'description': description,
        'metrics': metrics,
        'filters': filters,
      });

      return true;
    } catch (e) {
      print('Error updating report: $e');
      return false;
    }
  }

  /// Delete report
  Future<bool> deleteReport(String reportId) async {
    try {
      await _firestore.collection(_reportsCollection).doc(reportId).delete();
      return true;
    } catch (e) {
      print('Error deleting report: $e');
      return false;
    }
  }

  /// Generate report export
  Future<String?> generateReportExport({
    required String reportId,
    required ExportFormat format,
  }) async {
    try {
      final generatedReportId =
          _firestore.collection(_generatedReportsCollection).doc().id;

      final report = await getReport(reportId);
      if (report == null) return null;

      final generatedReport = GeneratedReport(
        id: generatedReportId,
        reportId: reportId,
        reportName: report.name,
        format: format,
        status: ReportStatus.generating,
        requestedAt: DateTime.now(),
        requestedBy: _auth.currentUser?.email ?? 'system',
      );

      await _firestore
          .collection(_generatedReportsCollection)
          .doc(generatedReportId)
          .set(generatedReport.toFirestore());

      return generatedReportId;
    } catch (e) {
      print('Error generating export: $e');
      return null;
    }
  }

  /// Get generated report
  Future<GeneratedReport?> getGeneratedReport(String generatedReportId) async {
    try {
      final doc = await _firestore
          .collection(_generatedReportsCollection)
          .doc(generatedReportId)
          .get();

      if (!doc.exists) return null;

      return GeneratedReport.fromFirestore(doc);
    } catch (e) {
      print('Error fetching generated report: $e');
      return null;
    }
  }

  /// Get all generated reports for a report
  Future<List<GeneratedReport>> getGeneratedReportsForReport({
    required String reportId,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_generatedReportsCollection)
          .where('reportId', isEqualTo: reportId)
          .orderBy('requestedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => GeneratedReport.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching generated reports: $e');
      return [];
    }
  }

  /// Schedule recurring report
  Future<String?> scheduleReport({
    required String reportId,
    required String frequency,
    required DateTime startDate,
    DateTime? endDate,
  }) async {
    try {
      final scheduleId =
          _firestore.collection(_reportSchedulesCollection).doc().id;

      await _firestore
          .collection(_reportSchedulesCollection)
          .doc(scheduleId)
          .set({
        'reportId': reportId,
        'frequency': frequency,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'isActive': true,
        'createdAt': Timestamp.now(),
        'createdBy': _auth.currentUser?.email,
      });

      return scheduleId;
    } catch (e) {
      print('Error scheduling report: $e');
      return null;
    }
  }

  /// Get all active scheduled reports
  Future<List<Map<String, dynamic>>> getScheduledReports() async {
    try {
      final snapshot = await _firestore
          .collection(_reportSchedulesCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error fetching scheduled reports: $e');
      return [];
    }
  }

  /// Cancel scheduled report
  Future<bool> cancelScheduledReport(String scheduleId) async {
    try {
      await _firestore
          .collection(_reportSchedulesCollection)
          .doc(scheduleId)
          .update({
        'isActive': false,
        'cancelledAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Error cancelling scheduled report: $e');
      return false;
    }
  }

  /// Update generated report status
  Future<bool> updateGeneratedReportStatus({
    required String generatedReportId,
    required ReportStatus status,
    String? downloadUrl,
    String? errorMessage,
  }) async {
    try {
      await _firestore
          .collection(_generatedReportsCollection)
          .doc(generatedReportId)
          .update({
        'status': status.toString().split('.').last,
        'completedAt':
            status == ReportStatus.completed ? Timestamp.now() : null,
        'downloadUrl': downloadUrl,
        'errorMessage': errorMessage,
      });

      return true;
    } catch (e) {
      print('Error updating report status: $e');
      return false;
    }
  }

  /// Export report data as CSV
  String generateCsvContent({
    required String reportName,
    required List<List<String>> data,
  }) {
    final header = [
      'Report: $reportName',
      'Generated: ${DateTime.now().toIso8601String()}',
    ];

    final csvLines = [header.join(','), ''];

    // Add data rows
    for (var row in data) {
      csvLines.add(row.map((cell) => '"$cell"').join(','));
    }

    return csvLines.join('\n');
  }

  /// Get report generation statistics
  Future<Map<String, dynamic>> getReportStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_reportsCollection)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final typeCount = <String, int>{};
      var totalReports = 0;

      for (var doc in snapshot.docs) {
        final type = doc['type'] as String;
        typeCount[type] = (typeCount[type] ?? 0) + 1;
        totalReports++;
      }

      return {
        'totalReports': totalReports,
        'reportsByType': typeCount,
      };
    } catch (e) {
      print('Error getting report statistics: $e');
      return {};
    }
  }
}
