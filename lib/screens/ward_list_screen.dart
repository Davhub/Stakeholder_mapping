import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mapping/model/model.dart';
import 'package:mapping/screens/ward_stakeholder_screen.dart';

class WardListScreen extends StatefulWidget {
  const WardListScreen({super.key});

  @override
  State<WardListScreen> createState() => _WardListScreenState();
}

class _WardListScreenState extends State<WardListScreen> {
  Map<String, int> wardCounts = {};
  bool isLoading = true;
  String? userState;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUserState();
    await _loadWards();
  }

  Future<void> _getUserState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userState = userDoc.data()?['state'] ?? 'Lagos';
          });
        } else {
          setState(() {
            userState = 'Lagos';
          });
        }
      }
    } catch (e) {
      setState(() {
        userState = 'Lagos';
      });
    }
  }

  Future<void> _loadWards() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Query stakeholders based on user's state
      final querySnapshot = await FirebaseFirestore.instance
          .collection('stakeholders')
          .where('state', isEqualTo: userState)
          .get();

      // Count stakeholders per ward using Stakeholder model for proper type handling
      Map<String, int> counts = {};
      for (var doc in querySnapshot.docs) {
        Stakeholder stakeholder = Stakeholder.fromFirestore(doc);
        String ward = stakeholder.ward.isEmpty ? 'Unknown' : stakeholder.ward;
        counts[ward] = (counts[ward] ?? 0) + 1;
      }

      setState(() {
        wardCounts = Map.fromEntries(
          counts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
        );
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading wards: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Wards',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : wardCounts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadWards,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade400,
                              Colors.purple.shade600
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
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
                                Icons.map_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${wardCounts.length} Wards',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total: ${wardCounts.values.reduce((a, b) => a + b)} stakeholders',
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
                      const SizedBox(height: 24),

                      // Wards List
                      ...wardCounts.entries.map((entry) {
                        return _buildWardCard(
                          ward: entry.key,
                          count: entry.value,
                        );
                      }).toList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWardCard({
    required String ward,
    required int count,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WardStakeholderScreen(
                wardName: ward,
              ),
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
                    colors: [Colors.purple.shade300, Colors.purple.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ward,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count ${count == 1 ? 'stakeholder' : 'stakeholders'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Wards Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no wards available in your state.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
