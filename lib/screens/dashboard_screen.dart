import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:risdi/component/component.dart';
import 'package:risdi/model/model.dart';
import 'package:risdi/screens/stakeholder_view.dart';
import 'package:risdi/services/stakeholder_cache_service.dart';
import 'package:risdi/services/app_state_service.dart';
import 'package:risdi/services/location_service.dart';
import 'package:risdi/core/utils/location_utils.dart';
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late StakeholderCacheService _cacheService;
  late AppStateService _appStateService;
  late LocationService _locationService;
  Box<Stakeholder>? stakeholderBox;
  List<Stakeholder> allStakeholders = [];
  List<Stakeholder> filteredStakeholders = [];
  bool isLoading = true;
  String? errorMessage;
  StreamSubscription? firestoreSubscription;

  String? currentUserState;
  String? selectedLg;
  String? selectedWard;

  List<String> lgs = [];
  List<String> wards = [];
  bool isLoadingLGAs = false;
  bool isLoadingWards = false;
  String? lgaLoadError;
  String? wardLoadError;
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  List<Stakeholder> searchResults = [];

  @override
  void initState() {
    super.initState();
    _cacheService = StakeholderCacheService();
    _appStateService = AppStateService();
    _appStateService.addListener(_onAppStateChanged);
    _initializeLocationService();


    // Fetch user state first, then initialize data
    fetchCurrentUserState().then((_) {
      // After user state is fetched, initialize data
      initializeData();
    });
  }

  /// Initialize LocationService for dynamic location data from Firestore
  Future<void> _initializeLocationService() async {
    _locationService = LocationService();
    try {
      await _locationService.initialize();
      debugPrint('LocationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing LocationService: $e');
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
      final lgas = await _locationService.getLGAsForState(state);
      if (mounted) {
        setState(() {
          lgs = lgas;
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
      final wardList = await _locationService.getWardsForLGA(state, lga);
      if (mounted) {
        setState(() {
          wards = wardList;
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

  void _onAppStateChanged() {
    if (mounted && _appStateService.isInitialized) {
      setState(() {
        allStakeholders = _appStateService.allStakeholders;
        filteredStakeholders = List.from(allStakeholders);
        updateLgsAndWards();
      });
    }
  }

  @override
  void dispose() {
    _appStateService.removeListener(_onAppStateChanged);
    firestoreSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchCurrentUserState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      debugPrint('🔐 [AUTH] Current user UID: ${user?.uid}, email: ${user?.email}');
      if (user != null) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          final userData = docSnapshot.data();
          currentUserState = userData?['state'] as String?;
          debugPrint('📍 [STATE] User document fields: ${userData?.keys.toList()}');
          debugPrint('📍 [STATE] User state retrieved: "$currentUserState" (type: ${currentUserState.runtimeType}, length: ${(currentUserState ?? '').length})');
          
          if (currentUserState != null) {
            // Only set listener if not already set
            if (firestoreSubscription == null) {
              debugPrint('🔍 [FIRESTORE-SCOPE] Setting Firestore listener scoped to: "$currentUserState"');
              setFirestoreListener();
            }
          } else {
            debugPrint('⚠️  [STATE-ERROR] State field is null for user ${user.uid}');
            setState(() {
              isLoading = false;
              errorMessage = 'State not found for the current user.';
            });
          }
        } else {
          debugPrint('⚠️  [STATE-ERROR] User document does not exist for UID: ${user.uid}');
        }
      }
    } catch (e) {
      debugPrint('❌ [STATE-ERROR] Error fetching user state: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching user state: $e';
      });
    }
  }

  Future<void> initializeData() async {
    try {
      // If data is already in app state, just use it (prevents reload on navigation back)
      if (_appStateService.isInitialized &&
          _appStateService.userState == currentUserState) {
        final cachedStakeholders = _appStateService.allStakeholders;
        setState(() {
          allStakeholders = cachedStakeholders;
          filteredStakeholders = List.from(allStakeholders);
          isLoading = false;
        });
        updateLgsAndWards();
        return;
      }

      // First time - load from cache
      if (_cacheService.isCachePopulated()) {
        final cachedStakeholders =
            _cacheService.getStakeholdersByState(currentUserState ?? 'Lagos');
        setState(() {
          allStakeholders = cachedStakeholders;
          filteredStakeholders = List.from(allStakeholders);
          isLoading = false;
        });
        updateLgsAndWards();

        // Update app state for future use
        if (currentUserState != null) {
          await _appStateService.initialize(currentUserState!);
        }
      } else {
        setState(() {
          isLoading = true;
        });
      }

      // Update Hive box reference if needed (for legacy code)
      stakeholderBox = await Hive.openBox<Stakeholder>('stakeholderBox');
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load cached data: $e';
      });
    }
  }

  void setFirestoreListener() {
    debugPrint('🔄 [FIRESTORE-QUERY] Setting up listener for state: $currentUserState');
    firestoreSubscription = FirebaseFirestore.instance
        .collection('stakeholders')
        .where('state', isEqualTo: currentUserState)
        .snapshots()
        .listen((snapshot) async {
      debugPrint('📊 [FIRESTORE-DATA] Received ${snapshot.docs.length} stakeholders for state: $currentUserState');
      List<Stakeholder> fetchedStakeholders = snapshot.docs
          .map((doc) => Stakeholder.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      // Update cache service
      await _cacheService.cacheStakeholders(fetchedStakeholders);

      // Update app state (this will notify all listeners)
      _appStateService.updateStakeholders(fetchedStakeholders);

      // Update Hive box (legacy support)
      await stakeholderBox?.clear();
      await stakeholderBox?.addAll(fetchedStakeholders);

      if (mounted) {
        setState(() {
          allStakeholders = fetchedStakeholders;
          filteredStakeholders = allStakeholders;
          updateLgsAndWards();
          isLoading = false;
        });
      }

      debugPrint('Hive data updated from Firestore in real time.');
    }, onError: (error) {
      debugPrint('Error listening to Firestore updates: $error');
    });
  }

  void updateLgsAndWards() {
    // Load LGAs from Firestore when current user state is available
    if (currentUserState != null && currentUserState!.isNotEmpty) {
      _loadLGAsForState(currentUserState!);
    }
    
    // Reset wards if LG changed or is not available
    if (selectedLg != null && !lgs.contains(selectedLg)) {
      selectedLg = null;
      wards = [];
    }
  }

  void filterStakeholders() {
    setState(() {
      filteredStakeholders = allStakeholders.where((stakeholder) {
        final matchesLg = selectedLg == null ||
            (stakeholder.lg.isNotEmpty && selectedLg != null &&
                LocationUtils.equalsIgnoreCase(stakeholder.lg, selectedLg!));
        final matchesWard = selectedWard == null ||
            (stakeholder.ward.isNotEmpty && selectedWard != null &&
                LocationUtils.equalsIgnoreCase(stakeholder.ward, selectedWard!));
        return matchesLg && matchesWard;
      }).toList();
      debugPrint('🔍 [FILTER] Applied LGA: ${selectedLg ?? "none"}, Ward: ${selectedWard ?? "none"} => ${filteredStakeholders.length} results');
    });
  }

  void resetFilter() {
    setState(() {
      selectedLg = null;
      selectedWard = null;
      filteredStakeholders = allStakeholders;
      wards.clear();
    });
  }

  void _searchStakeholders(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredStakeholders = allStakeholders;
      } else {
        filteredStakeholders = allStakeholders.where((stakeholder) {
          return stakeholder.fullName
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              stakeholder.association
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              stakeholder.lg.toLowerCase().contains(query.toLowerCase()) ||
              stakeholder.ward.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Reset app state
      _appStateService.reset();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Know Your Stakeholder",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Find and manage your stakeholder contacts",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Debug button for testing LocationService
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Debug Tests'),
                          content: const Text(
                            'Run diagnostic tests to check LocationService and cache?\n\n'
                            'This will test:\n'
                            '• Firestore wards collection access\n'
                            '• LocationService functionality\n'
                            '• Stakeholder queries\n'
                            '• Hive cache contents\n\n'
                            'Check console for results.'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _runDiagnosticTests();
                              },
                              child: const Text('Run Tests'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.bug_report),
                    tooltip: 'Run Debug Tests',
                  ),
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text(
                              'Are you sure you want to logout?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: _logout,
                                child: const Text(
                                  'Yes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Bar
              TextField(
                controller: _searchController,
                onChanged: _searchStakeholders,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Search stakeholders...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Statistics Cards
              if (currentUserState != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        '$currentUserState State',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${allStakeholders.length} Total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Filter Section with Loading & Error States
              if (isLoadingLGAs)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (lgaLoadError != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Error loading LGAs: $lgaLoadError',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                )
              else if (lgs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    '⚠️ No LGA data available. Wards collection may be empty or state mismatch.',
                    style: TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedLg,
                        hint: const Text('Select LGA'),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: lgs.map((lg) {
                          return DropdownMenuItem(
                            value: lg,
                            child: Text(
                              lg,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedLg = value;
                            selectedWard = null; // Reset ward when LGA changes
                          });
                          // Load wards for selected LGA
                          if (value != null && value.isNotEmpty && currentUserState != null) {
                            _loadWardsForLGA(currentUserState!, value);
                          }
                          filterStakeholders();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: isLoadingWards
                        ? const Center(
                            child: SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : wardLoadError != null
                          ? Center(
                              child: Tooltip(
                                message: wardLoadError,
                                child: const Icon(Icons.error, color: Colors.red, size: 30),
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              value: selectedWard,
                              hint: const Text('Select Ward'),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: wards.isEmpty
                                ? [
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text('No wards available'),
                                      enabled: false,
                                    )
                                  ]
                                : wards.map((ward) {
                                    return DropdownMenuItem(
                                      value: ward,
                                      child: Text(
                                        ward,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                              onChanged: wards.isEmpty ? null : (value) {
                                setState(() {
                                  selectedWard = value;
                                  filterStakeholders();
                                });
                              },
                            ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),

              // Reset Filter Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: resetFilter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Reset Filter',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recent Stakeholders Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Stakeholders",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredStakeholders.length} Found',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Loading, Error, or Stakeholders List
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: fetchCurrentUserState,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              else if (filteredStakeholders.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Stakeholders Found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Stakeholders List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredStakeholders.length,
                  itemBuilder: (context, index) {
                    final stakeholder = filteredStakeholders[index];
                    return _buildStakeholderTile(stakeholder);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Stakeholder List Tile
  Widget _buildStakeholderTile(Stakeholder stakeholder) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => StakeholderView(holder: stakeholder),
          ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                radius: 24,
                child: Text(
                  stakeholder.fullName.isNotEmpty
                      ? stakeholder.fullName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${stakeholder.lg}, ${stakeholder.ward}',
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
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Run diagnostic tests to check LocationService and cache
  void _runDiagnosticTests() {
    // Import the test runner dynamically to avoid build issues
    Future.microtask(() async {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Running diagnostic tests... Check console')),
        );

        // Import and run tests
        final testRunner = await _loadTestRunner();
        testRunner();

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error running tests: $e')),
        );
      }
    });
  }

  /// Dynamically load the test runner
  Future<Function> _loadTestRunner() async {
    // Since we can't import at runtime, we'll run the tests directly
    // Import the services we need
    final locationTestService = await _loadLocationTestService();
    final hiveInspector = await _loadHiveInspector();

    return () {
      debugPrint('🔬 DASHBOARD DIAGNOSTIC TESTS');
      debugPrint('=' * 50);

      // Test 1: Direct Firestore access
      debugPrint('TEST 1: Direct Firestore Access');
      locationTestService.testDirectFirestoreAccess();

      // Test 2: LocationService
      debugPrint('\nTEST 2: LocationService Functionality');
      locationTestService.testLocationService();

      // Test 3: Stakeholder queries
      debugPrint('\nTEST 3: Stakeholder Queries');
      locationTestService.testStakeholderQueries();

      // Test 4: Hive cache
      debugPrint('\nTEST 4: Hive Cache Inspection');
      hiveInspector.inspectHiveCache();

      debugPrint('\n🏁 Tests Complete - Check console output');
    };
  }

  Future<dynamic> _loadLocationTestService() async {
    // Return the test functions
    return _LocationTestServiceWrapper();
  }

  Future<dynamic> _loadHiveInspector() async {
    return _HiveInspectorWrapper();
  }
}

/// Wrapper classes to access test functions
class _LocationTestServiceWrapper {
  void testDirectFirestoreAccess() {
    // Direct Firestore test
    FirebaseFirestore.instance.collection('wards').get().then((snapshot) {
      debugPrint('✅ Direct Firestore: Found ${snapshot.docs.length} documents in wards collection');
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first.data();
        debugPrint('  Sample: state="${doc['state']}", lga="${doc['lga']}", ward="${doc['ward']}"');
      }
    }).catchError((e) {
      debugPrint('❌ Direct Firestore failed: $e');
    });
  }

  void testLocationService() {
    debugPrint('LocationService test would run here (needs full service initialization)');
  }

  void testStakeholderQueries() {
    // Test stakeholder query with fixed LGA field
    FirebaseFirestore.instance
        .collection('stakeholders')
        .where('state', isEqualTo: 'Lagos')
        .where('LGA', isEqualTo: 'Agege')
        .limit(3)
        .get()
        .then((snapshot) {
          debugPrint('✅ Stakeholder query: Found ${snapshot.docs.length} results for Lagos/Agege');
        })
        .catchError((e) {
          debugPrint('❌ Stakeholder query failed: $e');
        });
  }
}

class _HiveInspectorWrapper {
  void inspectHiveCache() {
    debugPrint('Hive cache inspection would run here (needs Hive initialization)');
    debugPrint('Note: To clear cache, call StakeholderCacheService().clearCache()');
  }
}
