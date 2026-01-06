import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:mapping/component/recent_stakeholders_manager.dart';
import 'package:mapping/model/model.dart';
import 'package:mapping/screens/stakeholder_list_screen.dart';
import 'package:mapping/screens/stakeholder_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> recentStakeholders = [];
  String? currentUserState;
  bool isLoading = true;
  int totalStakeholders = 0;
  int totalFavorites = 0;
  int totalAssociations = 0;
  int totalWards = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getCurrentUserState();
    await _loadDashboardData();
    await _loadRecentStakeholders();
  }

  Future<void> _getCurrentUserState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            currentUserState = userDoc.data()?['state'] ?? 'Lagos';
          });
        } else {
          setState(() {
            currentUserState = 'Lagos';
          });
        }
      }
    } catch (e) {
      setState(() {
        currentUserState = 'Lagos';
      });
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      // Try loading from Hive first for quick display
      final box = await Hive.openBox<Stakeholder>('stakeholders');
      List<Stakeholder> hiveStakeholders =
          box.values.where((s) => s.state == currentUserState).toList();

      if (hiveStakeholders.isNotEmpty) {
        _updateCounts(hiveStakeholders);
      }

      // Load fresh data from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('stakeholder')
          .where('state', isEqualTo: currentUserState)
          .get();

      List<Stakeholder> stakeholders = querySnapshot.docs
          .map((doc) => Stakeholder.fromFirestore(doc))
          .toList();

      // Update Hive cache
      await box.clear();
      await box.addAll(stakeholders);

      _updateCounts(stakeholders);
    } catch (e) {
      print('Error loading dashboard data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _updateCounts(List<Stakeholder> stakeholders) {
    setState(() {
      totalStakeholders = stakeholders.length;
      totalAssociations = stakeholders.map((s) => s.association).toSet().length;
      totalWards = stakeholders.map((s) => s.ward).toSet().length;
      // Favorites would come from a favorites collection/preference
      totalFavorites = 0; // Placeholder for now
      isLoading = false;
    });
  }

  Future<void> _loadRecentStakeholders() async {
    try {
      List<Map<String, dynamic>> recent =
          await RecentStakeholdersManager.getRecentStakeholders();
      setState(() {
        recentStakeholders = recent.take(5).toList(); // Show only 5 most recent
      });
    } catch (e) {
      print('Error loading recent stakeholders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _initializeData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              if (currentUserState != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade500, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.location_city_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$currentUserState State',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Managing $totalStakeholders stakeholder${totalStakeholders != 1 ? 's' : ''}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // Dashboard Grid (2x2)
              const Text(
                "Quick Overview",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildDashboardCard(
                    title: 'Total Stakeholders',
                    count: totalStakeholders.toString(),
                    icon: Icons.people_rounded,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const StakeholderListScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    title: 'Favorites',
                    count: totalFavorites.toString(),
                    icon: Icons.favorite_rounded,
                    gradient: LinearGradient(
                      colors: [Colors.pink.shade400, Colors.pink.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    onTap: () {
                      // Navigate to favorites screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Favorites feature coming soon!')),
                      );
                    },
                  ),
                  _buildDashboardCard(
                      title: 'Associations',
                      count: totalAssociations.toString(),
                      icon: Icons.business_rounded,
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade400, Colors.teal.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        // Navigate to associations view
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StakeholderListScreen(),
                          ),
                        );
                      },
                    ),
                    _buildDashboardCard(
                      title: 'Total Wards',
                      count: totalWards.toString(),
                      icon: Icons.map_rounded,
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.purple.shade600
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      onTap: () {
                        // Navigate to wards view
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StakeholderListScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Recent Stakeholders Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Recently Viewed",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (recentStakeholders.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const StakeholderListScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text("View All"),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

              // Recent Stakeholders List
              if (recentStakeholders.isEmpty)
                _buildEmptyRecentState()
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentStakeholders.length,
                  itemBuilder: (context, index) {
                    final stakeholder = recentStakeholders[index];
                    return _buildRecentStakeholderTile(stakeholder);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String count,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRecentState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            "No Recent Activity",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start browsing stakeholders to see your recent activity here",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StakeholderListScreen(),
                ),
              );
            },
            icon: const Icon(Icons.people_rounded),
            label: const Text("Browse Stakeholders"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStakeholderTile(Map<String, dynamic> stakeholderData) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Stakeholder stakeholder = Stakeholder(
            fullName: stakeholderData['fullName'] ?? '',
            association: stakeholderData['association'] ?? '',
            lg: stakeholderData['lg'] ?? '',
            ward: stakeholderData['ward'] ?? '',
            phoneNumber: stakeholderData['phoneNumber'] ?? '',
            email: stakeholderData['email'] ?? '',
            whatsappNumber: stakeholderData['whatsappNumber'] ?? '',
            levelOfAdministration:
                stakeholderData['levelOfAdministration'] ?? '',
            country: stakeholderData['country'] ?? '',
            state: stakeholderData['state'] ?? '',
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StakeholderView(holder: stakeholder),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    (stakeholderData['fullName'] ?? 'S')[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stakeholderData['fullName'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stakeholderData['association'] ?? 'No Association',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${stakeholderData['lg'] ?? 'Unknown'}, ${stakeholderData['ward'] ?? 'Unknown'}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey[400], size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
