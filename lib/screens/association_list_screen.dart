import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mapping/model/model.dart';
import 'package:mapping/screens/association_stakeholder_screen.dart';

class AssociationListScreen extends StatefulWidget {
  const AssociationListScreen({super.key});

  @override
  State<AssociationListScreen> createState() => _AssociationListScreenState();
}

class _AssociationListScreenState extends State<AssociationListScreen> {
  Map<String, int> associationCounts = {};
  bool isLoading = true;
  String? userState;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _getUserState();
    await _loadAssociations();
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

  Future<void> _loadAssociations() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Query stakeholders based on user's state
      final querySnapshot = await FirebaseFirestore.instance
          .collection('stakeholders')
          .where('state', isEqualTo: userState)
          .get();

      // Count stakeholders per association using Stakeholder model
      Map<String, int> counts = {};
      for (var doc in querySnapshot.docs) {
        Stakeholder stakeholder = Stakeholder.fromFirestore(doc);
        String association = stakeholder.association.isEmpty
            ? 'Unknown'
            : stakeholder.association;
        counts[association] = (counts[association] ?? 0) + 1;
      }

      setState(() {
        associationCounts = Map.fromEntries(
          counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
        );
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading associations: $e')),
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
          'Associations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : associationCounts.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadAssociations,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade400,
                              Colors.teal.shade600
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.3),
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
                                Icons.business_rounded,
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
                                    '${associationCounts.length} Associations',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Total: ${associationCounts.values.reduce((a, b) => a + b)} stakeholders',
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

                      // Associations List
                      ...associationCounts.entries.map((entry) {
                        return _buildAssociationCard(
                          association: entry.key,
                          count: entry.value,
                        );
                      }).toList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAssociationCard({
    required String association,
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
              builder: (context) => AssociationStakeholderScreen(
                associationName: association,
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
                    colors: [Colors.teal.shade300, Colors.teal.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_rounded,
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
                      association,
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
              Icons.business_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No Associations Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no associations available in your state.',
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
