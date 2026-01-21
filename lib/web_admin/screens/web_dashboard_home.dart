import 'package:flutter/material.dart';
import 'package:mapping/web_admin/services/admin_firestore_service.dart';
import 'package:mapping/web_admin/models/dashboard_models.dart';
import 'package:mapping/web_admin/widgets/kpi_card.dart';
import 'package:mapping/model/model.dart';

class WebDashboardHome extends StatefulWidget {
  const WebDashboardHome({Key? key}) : super(key: key);

  @override
  State<WebDashboardHome> createState() => _WebDashboardHomeState();
}

class _WebDashboardHomeState extends State<WebDashboardHome> {
  final AdminFirestoreService _service = AdminFirestoreService();
  late Future<DashboardKPIs> _kpisFuture;
  Stream<List<Stakeholder>>? _recentStakeholdersStream;
  String? _adminState;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      _adminState = await _service.getAdminState();
      if (_adminState != null) {
        setState(() {
          _kpisFuture = _loadKPIs();
          // Use createdAt ordering for recent stakeholders (descending = newest first)
          // Note: This requires a Firestore composite index
          _recentStakeholdersStream = _service
              .getStakeholdersStream(
                adminState: _adminState!,
                limit: 5,
                orderBy: 'createdAt',
                descending: true,
              )
              .map((snapshot) => snapshot.docs
                  .map((doc) => Stakeholder.fromFirestore(doc))
                  .toList())
              .handleError((error) {
            print('Error in stakeholders stream: $error');
            // Fallback to empty list on error
            return <Stakeholder>[];
          });
          _isInitializing = false;
        });
      } else {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<DashboardKPIs> _loadKPIs() async {
    if (_adminState == null) {
      return DashboardKPIs(
        totalStakeholders: 0,
        totalLGAs: 0,
        totalWards: 0,
        recentlyAdded: 0,
      );
    }

    final totalStakeholders = await _service.getTotalStakeholders(_adminState!);
    final totalLGAs = await _service.getTotalLGAs(_adminState!);
    final totalWards = await _service.getTotalWards(_adminState!);
    final recentlyAdded =
        await _service.getRecentlyAddedStakeholders(_adminState!);

    // Calculate growth percentage (comparing with previous period)
    // For now, using a simple calculation based on recent additions
    double? growthPercentage;
    if (totalStakeholders > 0) {
      growthPercentage = (recentlyAdded / totalStakeholders) * 100;
    }

    return DashboardKPIs(
      totalStakeholders: totalStakeholders,
      totalLGAs: totalLGAs,
      totalWards: totalWards,
      recentlyAdded: recentlyAdded,
      growthPercentage: growthPercentage,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading dashboard...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_adminState == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Unable to load admin state',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadDashboardData();
        setState(() {
          _kpisFuture = _loadKPIs();
        });
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(),
            const SizedBox(height: 32),

            // KPI Cards
            FutureBuilder<DashboardKPIs>(
              future: _kpisFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildKPISkeletons();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading KPIs: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final kpis = snapshot.data!;
                return _buildKPIGrid(kpis);
              },
            ),

            const SizedBox(height: 32),

            // Recent Stakeholders Section
            _buildRecentStakeholdersSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade50,
            Colors.purple.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.dashboard_rounded,
              size: 40,
              color: Colors.deepPurple.shade700,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome to Admin Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Managing stakeholders for $_adminState State',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISkeletons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: const [
            KPICardSkeleton(),
            KPICardSkeleton(),
            KPICardSkeleton(),
            KPICardSkeleton(),
          ],
        );
      },
    );
  }

  Widget _buildKPIGrid(DashboardKPIs kpis) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            KPICard(
              title: 'Total Stakeholders',
              value: kpis.totalStakeholders.toString(),
              icon: Icons.people_rounded,
              color: Colors.blue,
              subtitle: 'Registered stakeholders',
              growthPercentage: kpis.growthPercentage,
            ),
            KPICard(
              title: 'Total LGAs',
              value: kpis.totalLGAs.toString(),
              icon: Icons.location_city_rounded,
              color: Colors.green,
              subtitle: 'Local Government Areas',
            ),
            KPICard(
              title: 'Total Wards',
              value: kpis.totalWards.toString(),
              icon: Icons.place_rounded,
              color: Colors.orange,
              subtitle: 'Electoral wards covered',
            ),
            KPICard(
              title: 'Recent Additions',
              value: kpis.recentlyAdded.toString(),
              icon: Icons.trending_up_rounded,
              color: Colors.purple,
              subtitle: 'Last 7 days',
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentStakeholdersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Stakeholders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // Navigate to stakeholders table
              },
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<Stakeholder>>(
          stream: _recentStakeholdersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Error loading recent stakeholders: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final stakeholders = snapshot.data ?? [];

            if (stakeholders.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No stakeholders found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stakeholders.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final stakeholder = stakeholders[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text(
                        stakeholder.fullName[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.deepPurple.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      stakeholder.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${stakeholder.lg} - ${stakeholder.ward}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          stakeholder.association,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stakeholder.phoneNumber,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
