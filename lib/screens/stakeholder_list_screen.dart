import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:mapping/model/model.dart';
import 'package:mapping/screens/stakeholder_view.dart';

class StakeholderListScreen extends StatefulWidget {
  final String? initialFilter;
  final String? filterValue;

  const StakeholderListScreen({
    super.key,
    this.initialFilter,
    this.filterValue,
  });

  @override
  State<StakeholderListScreen> createState() => _StakeholderListScreenState();
}

class _StakeholderListScreenState extends State<StakeholderListScreen> {
  List<Stakeholder> stakeholders = [];
  List<Stakeholder> filteredStakeholders = [];
  String searchQuery = '';
  String? selectedLGA;
  String? selectedWard;
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

    // Apply initial filter if provided
    if (widget.initialFilter != null && widget.filterValue != null) {
      if (widget.initialFilter == 'lga') {
        selectedLGA = widget.filterValue;
      } else if (widget.initialFilter == 'ward') {
        selectedWard = widget.filterValue;
      }
      _applyFilters();
    }
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
      List<Stakeholder> hiveStakeholders = box.values.toList();

      if (hiveStakeholders.isNotEmpty) {
        setState(() {
          stakeholders =
              hiveStakeholders.where((s) => s.state == userState).toList();
          filteredStakeholders = List.from(stakeholders);
          isLoading = false;
        });
      }

      // Load from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('stakeholders')
          .where('state', isEqualTo: userState)
          .get();

      List<Stakeholder> firestoreStakeholders = querySnapshot.docs
          .map((doc) => Stakeholder.fromFirestore(doc))
          .toList();

      // Update Hive cache
      await box.clear();
      await box.addAll(firestoreStakeholders);

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

  void _applyFilters() {
    setState(() {
      filteredStakeholders = stakeholders.where((stakeholder) {
        bool matchesSearch = searchQuery.isEmpty ||
            stakeholder.fullName
                .toLowerCase()
                .contains(searchQuery.toLowerCase()) ||
            stakeholder.association
                .toLowerCase()
                .contains(searchQuery.toLowerCase());

        bool matchesLGA = selectedLGA == null || stakeholder.lg == selectedLGA;
        bool matchesWard =
            selectedWard == null || stakeholder.ward == selectedWard;

        // Apply initial filter if provided
        bool matchesInitialFilter = true;
        if (widget.initialFilter == 'association' &&
            widget.filterValue != null) {
          matchesInitialFilter = stakeholder.association == widget.filterValue;
        } else if (widget.initialFilter == 'ward' &&
            widget.filterValue != null) {
          matchesInitialFilter = stakeholder.ward == widget.filterValue;
        }

        return matchesSearch &&
            matchesLGA &&
            matchesWard &&
            matchesInitialFilter;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      searchQuery = '';
      selectedLGA = null;
      selectedWard = null;
      searchController.clear();
      filteredStakeholders = List.from(stakeholders);
    });
  }

  List<String> _getUniqueLGAs() {
    return stakeholders.map((s) => s.lg).toSet().toList()..sort();
  }

  List<String> _getUniqueWards() {
    return stakeholders.map((s) => s.ward).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    // Build title based on filter
    String title = 'Stakeholder Directory';
    if (widget.initialFilter == 'association' && widget.filterValue != null) {
      title = widget.filterValue!;
    } else if (widget.initialFilter == 'ward' && widget.filterValue != null) {
      title = '${widget.filterValue!} Ward';
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (searchQuery.isNotEmpty ||
              selectedLGA != null ||
              selectedWard != null)
            IconButton(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear Filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.blue,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or association...',
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
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
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 12),
                // Filter Chips
                Row(
                  children: [
                    Expanded(
                      child: _buildFilterChip(
                        label: selectedLGA ?? 'All LGAs',
                        icon: Icons.location_city,
                        onTap: () => _showLGAFilterDialog(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFilterChip(
                        label: selectedWard ?? 'All Wards',
                        icon: Icons.map,
                        onTap: () => _showWardFilterDialog(),
                      ),
                    ),
                  ],
                ),
              ],
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
                if (searchQuery.isNotEmpty ||
                    selectedLGA != null ||
                    selectedWard != null)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
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

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.blue),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildStakeholderCard(Stakeholder stakeholder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
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
                width: 56,
                height: 56,
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
                    stakeholder.fullName.isNotEmpty
                        ? stakeholder.fullName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stakeholder.association,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${stakeholder.lg}, ${stakeholder.ward}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                searchQuery.isNotEmpty ||
                        selectedLGA != null ||
                        selectedWard != null
                    ? Icons.search_off
                    : Icons.people_outline,
                size: 64,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              searchQuery.isNotEmpty ||
                      selectedLGA != null ||
                      selectedWard != null
                  ? 'No Results Found'
                  : 'No Stakeholders Available',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              searchQuery.isNotEmpty ||
                      selectedLGA != null ||
                      selectedWard != null
                  ? 'Try adjusting your search or filters'
                  : 'Start adding stakeholders to see them here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (searchQuery.isNotEmpty ||
                selectedLGA != null ||
                selectedWard != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLGAFilterDialog() {
    final lgas = _getUniqueLGAs();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by LGA'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All LGAs'),
                leading: Radio<String?>(
                  value: null,
                  groupValue: selectedLGA,
                  onChanged: (value) {
                    setState(() {
                      selectedLGA = value;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  setState(() {
                    selectedLGA = null;
                  });
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ...lgas.map((lga) => ListTile(
                    title: Text(lga),
                    leading: Radio<String?>(
                      value: lga,
                      groupValue: selectedLGA,
                      onChanged: (value) {
                        setState(() {
                          selectedLGA = value;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                    ),
                    onTap: () {
                      setState(() {
                        selectedLGA = lga;
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showWardFilterDialog() {
    final wards = _getUniqueWards();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Ward'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All Wards'),
                leading: Radio<String?>(
                  value: null,
                  groupValue: selectedWard,
                  onChanged: (value) {
                    setState(() {
                      selectedWard = value;
                    });
                    _applyFilters();
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  setState(() {
                    selectedWard = null;
                  });
                  _applyFilters();
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ...wards.map((ward) => ListTile(
                    title: Text(ward),
                    leading: Radio<String?>(
                      value: ward,
                      groupValue: selectedWard,
                      onChanged: (value) {
                        setState(() {
                          selectedWard = value;
                        });
                        _applyFilters();
                        Navigator.pop(context);
                      },
                    ),
                    onTap: () {
                      setState(() {
                        selectedWard = ward;
                      });
                      _applyFilters();
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
