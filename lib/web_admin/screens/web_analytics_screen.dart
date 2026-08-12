import 'package:flutter/material.dart';
import 'package:impact_konnect/web_admin/services/admin_firestore_service.dart';
import 'package:impact_konnect/web_admin/models/dashboard_models.dart';

class WebAnalyticsScreen extends StatefulWidget {
  const WebAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<WebAnalyticsScreen> createState() => _WebAnalyticsScreenState();
}

class _WebAnalyticsScreenState extends State<WebAnalyticsScreen> {
  final AdminFirestoreService _service = AdminFirestoreService();
  String? _adminState;
  String? _adminOrganizationId;
  bool _isLoading = false;

  Map<String, int> _lgaDistribution = {};
  Map<String, int> _wardDistribution = {};
  Map<DateTime, int> _trendData = {};
  DUAContactAnalytics _contactAnalytics = DUAContactAnalytics(
    topContactedStakeholders: [],
    contactsByLGA: {},
    contactsByWard: {},
  );

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    _adminState = await _service.getAdminState();
    _adminOrganizationId = await _service.getAdminOrganizationId();
    if (_adminOrganizationId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final lgaData = await _service
          .getStakeholderDistributionByLGA(_adminOrganizationId!);
      final wardData = await _service
          .getStakeholderDistributionByWard(_adminOrganizationId!, null);
      final trendData =
          await _service.getStakeholderAdditionsTrend(_adminOrganizationId!);
      final contactAnalytics =
          await _service.getContactAnalytics(_adminState ?? '');

      setState(() {
        _lgaDistribution = lgaData;
        _wardDistribution = wardData;
        _trendData = trendData;
        _contactAnalytics = contactAnalytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_adminOrganizationId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Analytics & Reports',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _exportToCSV,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Export CSV'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // LGA Distribution
              _buildDistributionCard(
                'Distribution by Local Government Area',
                _lgaDistribution,
                Colors.blue,
              ),
              const SizedBox(height: 24),

              // Ward Distribution
              _buildDistributionCard(
                'Distribution by Ward',
                _wardDistribution,
                Colors.orange,
              ),
              const SizedBox(height: 24),

              // Trend Chart
              _buildTrendCard(),
              const SizedBox(height: 32),

              // DUA Report
              const Text(
                'DUA Report: Engagement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Which stakeholders are being reached, and where.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildTopContactedCard(),
              const SizedBox(height: 24),
              _buildDistributionCard(
                'Contact Activity by LGA',
                _contactAnalytics.contactsByLGA,
                Colors.teal,
              ),
              const SizedBox(height: 24),
              _buildDistributionCard(
                'Contact Activity by Ward',
                _contactAnalytics.contactsByWard,
                Colors.indigo,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionCard(
    String title,
    Map<String, int> data,
    Color color,
  ) {
    // Sort by value descending
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topEntries = sortedEntries.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: color, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (topEntries.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No data available',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...topEntries.map((entry) {
              final maxValue = sortedEntries.first.value;
              final percentage = (entry.value / maxValue * 100).toInt();

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${entry.value} stakeholders',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopContactedCard() {
    final stakeholders = _contactAnalytics.topContactedStakeholders;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.phone_in_talk_rounded, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text(
                'Most Contacted Stakeholders',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Counts phone-call and WhatsApp taps from the mobile app.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (stakeholders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No contact activity recorded yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stakeholders.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final s = stakeholders[index];
                return Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${s.lg} - ${s.ward}',
                            style:
                                TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${s.totalContacts} contact(s)',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${s.calls} call(s), ${s.whatsapp} WhatsApp',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTrendCard() {
    // Fill every day in the last 30 days so the chart shows true zeros
    // instead of silently skipping days with no additions.
    final today = DateTime.now();
    final days = List.generate(30, (i) {
      final date = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 29 - i));
      return MapEntry(date, _trendData[date] ?? 0);
    });
    final totalAdditions = days.fold<int>(0, (sum, e) => sum + e.value);
    final maxCount = days.fold<int>(1, (m, e) => e.value > m ? e.value : m);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: Colors.purple, size: 28),
              SizedBox(width: 12),
              Text(
                '30-Day Addition Trend',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$totalAdditions stakeholder(s) added in the last 30 days',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (totalAdditions == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No additions in the last 30 days',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.map((entry) {
                  final barHeight =
                      entry.value == 0 ? 2.0 : (entry.value / maxCount) * 140;
                  return Expanded(
                    child: Tooltip(
                      message:
                          '${entry.key.day}/${entry.key.month}/${entry.key.year}: '
                          '${entry.value} added',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (entry.value > 0)
                              Text(
                                '${entry.value}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Container(
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: entry.value == 0
                                    ? Colors.grey.shade200
                                    : Colors.purple,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (entry.key.day == 1 || entry.key.day % 5 == 0)
                              Text(
                                '${entry.key.day}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _exportToCSV() {
    // TODO: Implement CSV export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV export feature coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
