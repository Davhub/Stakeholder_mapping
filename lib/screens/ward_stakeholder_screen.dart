import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:mapping/model/model.dart';
import 'package:mapping/screens/stakeholder_view.dart';

class WardStakeholderScreen extends StatefulWidget {
  final String wardName;

  const WardStakeholderScreen({
    super.key,
    required this.wardName,
  });

  @override
  State<WardStakeholderScreen> createState() => _WardStakeholderScreenState();
}

class _WardStakeholderScreenState extends State<WardStakeholderScreen> {
  List<Stakeholder> stakeholders = [];
  List<Stakeholder> filteredStakeholders = [];
  String searchQuery = '';
  bool isLoading = true;
  String? userState;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _getUserState();
    await _loadStakeholders();
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

  Future<void> _loadStakeholders() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Try loading from Hive first
      final box = await Hive.openBox<Stakeholder>('stakeholders');
      List<Stakeholder> hiveStakeholders = box.values
          .where((s) => s.state == userState && s.ward == widget.wardName)
          .toList();

      if (hiveStakeholders.isNotEmpty) {
        setState(() {
          stakeholders = hiveStakeholders;
          filteredStakeholders = List.from(stakeholders);
          isLoading = false;
        });
      }

      // Load from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('stakeholders')
          .where('state', isEqualTo: userState)
          .where('ward', isEqualTo: widget.wardName)
          .get();

      List<Stakeholder> firestoreStakeholders = querySnapshot.docs
          .map((doc) => Stakeholder.fromFirestore(doc))
          .toList();

      setState(() {
        stakeholders = firestoreStakeholders;
        filteredStakeholders = List.from(stakeholders);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stakeholders: $e')),
        );
      }
    }
  }

  void _applySearchFilter() {
    setState(() {
      filteredStakeholders = stakeholders.where((stakeholder) {
        return stakeholder.fullName
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            stakeholder.association
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            stakeholder.lg.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          '${widget.wardName} Ward',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            color: Colors.purple,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search stakeholders...',
                prefixIcon: const Icon(Icons.search, color: Colors.purple),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
                _applySearchFilter();
              },
            ),
          ),

          // Results Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredStakeholders.length} ${filteredStakeholders.length == 1 ? 'Stakeholder' : 'Stakeholders'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Stakeholder List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredStakeholders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadStakeholders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredStakeholders.length,
                          itemBuilder: (context, index) {
                            return _buildStakeholderCard(
                                filteredStakeholders[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStakeholderCard(Stakeholder stakeholder) {
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
                    colors: [Colors.purple.shade300, Colors.purple.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    stakeholder.fullName.isNotEmpty
                        ? stakeholder.fullName[0].toUpperCase()
                        : 'S',
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
                      stakeholder.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stakeholder.association,
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
                        Icon(Icons.location_on_rounded,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            stakeholder.lg,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? 'No Stakeholders Found'
                  : 'No Results Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isEmpty
                  ? 'There are no stakeholders in this ward.'
                  : 'Try adjusting your search query.',
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
