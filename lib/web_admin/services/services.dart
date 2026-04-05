/// Service layer for web admin governance and analytics module
///
/// This file exports all web admin services for centralized access.
/// Services follow the repository pattern with Firestore backend integration.

// Existing services
export 'admin_firestore_service.dart';

// New governance and analytics services
export 'role_management_service.dart';
export 'audit_log_service.dart';
export 'activity_tracking_service.dart';
export 'advanced_analytics_service.dart';
export 'report_generation_service.dart';

/// Service initialization guide:
///
/// 1. RoleManagementService - User roles and permissions
///    - Manages role CRUD operations
///    - Handles permission checking and enforcement
///    - Default roles: Super Admin, Admin, Analyst, Viewer
///
/// 2. AuditLogService - Immutable audit trail
///    - Logs all admin actions (append-only)
///    - Provides audit log querying and filtering
///    - Supports export for compliance
///
/// 3. ActivityTrackingService - User activity monitoring
///    - Tracks user events (screen views, feature usage, etc.)
///    - Manages user sessions
///    - Aggregates daily metrics
///
/// 4. AdvancedAnalyticsService - Comprehensive analytics
///    - Stakeholder growth analysis
///    - Geographic distribution analysis
///    - Comparative period analysis
///    - Feature usage analytics
///
/// 5. ReportGenerationService - Report management
///    - Create and manage report templates
///    - Generate reports on demand
///    - Schedule recurring reports
///    - Export in multiple formats (CSV, Excel, PDF, JSON)

/// Usage example:
///
/// ```dart
/// // Check user permissions
/// final roleService = RoleManagementService();
/// final hasPermission = await roleService.userHasPermission('editStakeholders');
///
/// // Log an action
/// final auditService = AuditLogService();
/// await auditService.logStakeholderAction(
///   action: AuditAction.stakeholderCreated,
///   stakeholderId: 'stakeholder_123',
/// );
///
/// // Track user activity
/// final activityService = ActivityTrackingService();
/// await activityService.trackScreenView(screenName: 'DashboardScreen');
///
/// // Generate analytics report
/// final analyticsService = AdvancedAnalyticsService();
/// final report = await analyticsService.getStakeholderGrowthAnalysis(
///   startDate: DateTime.now().subtract(Duration(days: 30)),
///   endDate: DateTime.now(),
/// );
///
/// // Create and export report
/// final reportService = ReportGenerationService();
/// final reportId = await reportService.createReport(
///   title: 'Monthly Stakeholder Report',
///   reportType: ReportType.stakeholderGrowth,
///   dateRange: DateRange.thisMonth,
/// );
/// ```
