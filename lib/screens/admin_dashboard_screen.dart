import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:risdi/component/component.dart';
import 'package:risdi/screens/screen.dart';
import 'package:risdi/services/app_state_service.dart';
import 'package:risdi/core/utils/location_utils.dart';
import 'package:risdi/services/stakeholder_cache_service.dart';
import 'package:risdi/services/location_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String selectedLGA = '';
  String selectedWard = '';
  String adminState = '';
  int totalStakeholderCount = 0;
  String _searchQuery = '';

  // Location service for dynamic LGA/Ward data
  late LocationService _locationService;
  List<String> availableLGAs = [];
  List<String> availableWards = [];
  bool isLoadingLGAs = false;
  bool isLoadingWards = false;
  String? lgaLoadError;
  String? wardLoadError;

  final List<String> countries = ['Nigeria'];
  var holder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeLocationService();
      _getAdminState();
      _loadTotalStakeholderCount();
    });
  }

  /// Initialize LocationService for dynamic location data from Firestore
  Future<void> _initializeLocationService() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('⚠️ Firebase app not initialized; skipping location service bootstrap');
      return;
    }

    _locationService = LocationService();
    try {
      await _locationService.initialize();
      debugPrint('LocationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing LocationService: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading location data: $e')),
        );
      }
    }
  }

  /// Load LGAs for the specified state from Firestore
  Future<void> _loadLGAsForState(String state) async {
    if (state.isEmpty) return;
    
    setState(() {
      isLoadingLGAs = true;
      lgaLoadError = null;
    });

    try {
      debugPrint('🔄 [LGA-QUERY] Fetching LGAs for state: $state');
      final lgas = await _locationService.getLGAsForState(state);
      debugPrint('✅ [LGA-DATA] Loaded ${lgas.length} LGAs: $lgas');
      if (mounted) {
        setState(() {
          availableLGAs = lgas;
          isLoadingLGAs = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading LGAs: $e');
      if (mounted) {
        setState(() {
          lgaLoadError = 'Failed to load LGAs: $e';
          isLoadingLGAs = false;
        });
      }
    }
  }

  /// Load wards for the specified LGA from Firestore
  Future<void> _loadWardsForLGA(String state, String lga) async {
    if (state.isEmpty || lga.isEmpty) return;
    
    setState(() {
      isLoadingWards = true;
      wardLoadError = null;
    });

    try {
      final wards = await _locationService.getWardsForLGA(state, lga);
      if (mounted) {
        setState(() {
          availableWards = wards;
          isLoadingWards = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading wards: $e');
      if (mounted) {
        setState(() {
          wardLoadError = 'Failed to load wards: $e';
          isLoadingWards = false;
        });
      }
    }
  }

  // Fetch admin's state from Firestore and load LGAs
  Future<void> _getAdminState() async {
    if (Firebase.apps.isEmpty) {
      debugPrint('⚠️ Firebase app not initialized; skipping admin state bootstrap');
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('🔐 [AUTH] Current user: ${user?.email}');

      if (user == null) {
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final state = userDoc['state'] ?? '';
        debugPrint(
          '📍 [STATE] Admin state retrieved: "$state" (type: ${state.runtimeType}, length: ${(state as String).length})',
        );
        debugPrint('📍 [STATE] User document fields: ${userData?.keys.toList()}');

        if (mounted) {
          setState(() {
            adminState = state;
            selectedLGA = '';
            selectedWard = '';
            availableLGAs = [];
            availableWards = [];
          });
        }

        if (state.isNotEmpty) {
          await _loadLGAsForState(state);
        }
      } else {
        debugPrint('⚠️  [STATE-ERROR] User document does not exist for UID: ${user.uid}');
      }
    } catch (e) {
      debugPrint('❌ [STATE-ERROR] Error fetching user state: $e');
    }
  }

  // Load total stakeholder count from cache
  Future<void> _loadTotalStakeholderCount() async {
    try {
      final cacheService = StakeholderCacheService();
      final allStakeholders = await cacheService.getAllStakeholders();
      if (mounted) {
        setState(() {
          totalStakeholderCount = allStakeholders.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading total stakeholder count: $e');
    }
  }

  // Handle LGA selection and load wards for the selected LGA
  void _onLGAChanged(String? lga) {
    setState(() {
      selectedLGA = lga ?? '';
      selectedWard = '';
    });
    
    // Load wards for the selected LGA
    if (lga != null && lga.isNotEmpty && adminState.isNotEmpty) {
      _loadWardsForLGA(adminState, lga);
    }
  }

  // Reset filters for LGA and Ward
  void _resetFilter() {
    setState(() {
      selectedLGA = '';
      selectedWard = '';
    });
  }

  // Stream to fetch filtered stakeholders based on LGA and Ward
  Stream<QuerySnapshot> _getFilteredStakeholders() {
    if (Firebase.apps.isEmpty || adminState.isEmpty) {
      return Stream<QuerySnapshot>.empty();
    }

    final stakeholders = FirebaseFirestore.instance.collection('stakeholders');
    final query = stakeholders.where('state', isEqualTo: adminState);

    debugPrint('🔍 [FILTER-BUILD] State filter: $adminState');
    debugPrint('🔍 [FILTER-QUERY] Final query - State: $adminState, LGA: ${selectedLGA.isEmpty ? "none" : selectedLGA}, Ward: ${selectedWard.isEmpty ? "none" : selectedWard}');

    return query.snapshots();
  }

  void _deleteStakeholder(String stakeholderId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text(
                'Delete Stakeholder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to delete this stakeholder? This action cannot be undone.',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('stakeholders')
                    .doc(stakeholderId)
                    .delete();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text('Stakeholder deleted successfully!'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _editStakeholder(
      String stakeholderId, Map<String, dynamic> stakeholderData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditStakeholderScreen(
          stakeholderId: stakeholderId,
          stakeholderData: stakeholderData,
          data: {},
        ),
      ),
    );
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Reset app state
      final appStateService = AppStateService();
      appStateService.reset();
      if (mounted) {
        // Clear entire navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addStakeholder() {
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStakeholderScreen(adminId: adminId),
      ),
    );
    _scaffoldKey.currentState?.closeEndDrawer();
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Logout Confirmation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.filter_list,
                    color: Colors.deepPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filter Stakeholders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Search stakeholders',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
            const SizedBox(height: 12),
            if (isLoadingLGAs)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (lgaLoadError != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  lgaLoadError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              )
            else if (availableLGAs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '⚠️ No Local Government Areas found for state: $adminState',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: selectedLGA.isEmpty ? null : selectedLGA,
                items: availableLGAs.map((String lga) {
                  return DropdownMenuItem<String>(
                    value: lga,
                    child: Text(lga),
                  );
                }).toList(),
                hint: const Text('Select Local Government'),
                onChanged: _onLGAChanged,
                decoration: InputDecoration(
                  labelText: 'Local Government Area',
                  prefixIcon: const Icon(Icons.location_city, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            const SizedBox(height: 12),
            if (isLoadingWards)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (wardLoadError != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  wardLoadError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              )
            else if (availableWards.isEmpty && selectedLGA.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '⚠️ No wards found for LGA: $selectedLGA',
                  style: const TextStyle(color: Colors.orange, fontSize: 12),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: selectedWard.isEmpty ? null : selectedWard,
                items: availableWards.map((String ward) {
                  return DropdownMenuItem<String>(
                    value: ward,
                    child: Text(ward),
                  );
                }).toList(),
                hint: const Text('Select Ward'),
                onChanged: (ward) => setState(() => selectedWard = ward ?? ''),
                decoration: InputDecoration(
                  labelText: 'Ward',
                  prefixIcon: const Icon(Icons.map, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _resetFilter,
                icon: const Icon(Icons.clear_all, size: 20),
                label: const Text(
                  'Reset Filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade50,
              Colors.deepPurple.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.people,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Stakeholders',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalStakeholderCount',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminRail() {
    return Container(
      width: 92,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: NavigationRail(
        backgroundColor: Colors.white,
        selectedIndex: -1,
        minWidth: 88,
        labelType: NavigationRailLabelType.all,
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.person_add_outlined),
            selectedIcon: Icon(Icons.person_add),
            label: Text('Add'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.logout_outlined),
            selectedIcon: Icon(Icons.logout),
            label: Text('Logout'),
          ),
        ],
        onDestinationSelected: (value) {
          if (value == 0) {
            _addStakeholder();
          } else if (value == 1) {
            _showLogoutConfirmation();
          }
        },
      ),
    );
  }

  Widget _buildStakeholderList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredStakeholders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Colors.deepPurple,
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? <QueryDocumentSnapshot>[];
        final filteredDocs = allDocs.where((docSnap) {
          final data = docSnap.data() as Map<String, dynamic>;
          final docLga = LocationUtils.readStringField(data, ['lg', 'LGA', 'lga']) ?? '';
          final docWard = LocationUtils.readStringField(data, ['ward', 'Ward']) ?? '';
          final normalizedDocLga = LocationUtils.normalizeDisplay(docLga);
          final normalizedDocWard = LocationUtils.normalizeDisplay(docWard);

          if (selectedLGA.isNotEmpty) {
            final normalizedSelectedLga = LocationUtils.normalizeDisplay(selectedLGA);
            if (normalizedDocLga != normalizedSelectedLga) {
              return false;
            }
          }

          if (selectedWard.isNotEmpty) {
            final normalizedSelectedWard = LocationUtils.normalizeDisplay(selectedWard);
            if (normalizedDocWard != normalizedSelectedWard) {
              return false;
            }
          }

          if (_searchQuery.isNotEmpty) {
            final queryKey = LocationUtils.normalizeKey(_searchQuery);
            final name = LocationUtils.normalizeKey(data['fullName'] ?? '');
            final assoc = LocationUtils.normalizeKey(data['association'] ?? '');
            final phone = LocationUtils.normalizeKey(data['phoneNumber'] ?? '');
            final lgaKey = LocationUtils.normalizeKey(docLga);
            final wardKey = LocationUtils.normalizeKey(docWard);

            if (!(name.contains(queryKey) ||
                assoc.contains(queryKey) ||
                phone.contains(queryKey) ||
                lgaKey.contains(queryKey) ||
                wardKey.contains(queryKey))) {
              return false;
            }
          }

          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      size: 64,
                      color: Colors.deepPurple.shade300,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Stakeholders Found',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Try adjusting your filters or add new stakeholders',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final stakeholder = filteredDocs[index].data() as Map<String, dynamic>;
            final stakeholderName = stakeholder['fullName'] ?? 'No Name';
            final stakeholderId = filteredDocs[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AdminStakeholderViewScreen(
                        stakeholder: stakeholder,
                        stakeholderId: stakeholderId,
                        stakeholderData: stakeholder,
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
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade300,
                              Colors.deepPurple.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            stakeholderName.isNotEmpty
                                ? stakeholderName[0].toUpperCase()
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
                              stakeholderName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                                    '${stakeholder['lg'] ?? 'No LGA'}, ${stakeholder['ward'] ?? 'Ward'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.business,
                                  size: 14,
                                  color: Colors.grey[500],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    stakeholder['association'] ?? 'No Association',
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
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'Edit') {
                            _editStakeholder(stakeholderId, stakeholder);
                          } else if (value == 'Delete') {
                            _deleteStakeholder(stakeholderId);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'Edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20, color: Colors.blue),
                                SizedBox(width: 12),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'Delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$adminState Admin Dashboard',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _addStakeholder,
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Stakeholder',
          ),
          IconButton(
            onPressed: _showLogoutConfirmation,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Admin Tools',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Add Stakeholder'),
                onTap: () {
                  Navigator.of(context).pop();
                  _addStakeholder();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showLogoutConfirmation();
                },
              ),
            ],
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showSidebar = constraints.maxWidth >= 960;
          final content = SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFilterCard(),
                    const SizedBox(height: 16),
                    _buildStatsCard(),
                    const SizedBox(height: 16),
                    _buildStakeholderList(),
                    // SizedBox(
                    //   height: (constraints.maxHeight - 300).clamp(280.0, 520.0),
                    //   child: _buildStakeholderList(),
                    // ),
                  ],
                ),
              ),
            ),
          );

          if (!showSidebar) {
            return content;
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAdminRail(),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}
