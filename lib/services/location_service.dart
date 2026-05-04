import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to manage states, LGAs, and wards data from Firestore
/// Replaces hardcoded location data with dynamic Firestore queries
class LocationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for locations to minimize Firestore queries
  late Map<String, List<String>> _stateCache;
  late Map<String, List<String>> _lgaCache; // state -> LGAs
  late Map<String, List<String>> _wardCache; // lga -> wards
  
  bool _isInitialized = false;

  LocationService() {
    _stateCache = {};
    _lgaCache = {};
    _wardCache = {};
  }

  bool get isInitialized => _isInitialized;

  /// Initialize and load all states from Firestore
  Future<void> initialize() async {
    try {
      await _loadAllStates();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing LocationService: $e');
      _isInitialized = false;
    }
  }

  /// Load all states from the wards collection
  /// Wards collection structure: db -> wards collection -> documents with state field
  Future<void> _loadAllStates() async {
    try {
      // Fetch all unique states from wards collection
      final snapshot = await _firestore.collection('wards').get();
      
      Set<String> states = {};
      for (var doc in snapshot.docs) {
        final state = doc.data()['state'] as String?;
        if (state != null && state.isNotEmpty) {
          states.add(state);
        }
      }
      
      _stateCache = {'all': states.toList()..sort()};
      debugPrint('Loaded states: ${_stateCache['all']}');
    } catch (e) {
      debugPrint('Error loading states: $e');
    }
  }

  /// Get all available states
  List<String> getAllStates() {
    return _stateCache['all'] ?? [];
  }

  /// Get LGAs for a specific state
  /// Fetches from wards collection, extracts unique LGAs for the state
  Future<List<String>> getLGAsForState(String state) async {
    // Return from cache if available
    if (_lgaCache.containsKey(state)) {
      return _lgaCache[state] ?? [];
    }

    try {
      // Query wards collection for this state
      final snapshot = await _firestore
          .collection('wards')
          .where('state', isEqualTo: state)
          .get();

      Set<String> lgas = {};
      for (var doc in snapshot.docs) {
        final lga = doc.data()['lga'] as String?;
        if (lga != null && lga.isNotEmpty) {
          lgas.add(lga);
        }
      }

      List<String> lgaList = lgas.toList()..sort();
      _lgaCache[state] = lgaList;
      
      debugPrint('Loaded LGAs for $state: $lgaList');
      notifyListeners();
      return lgaList;
    } catch (e) {
      debugPrint('Error loading LGAs for state $state: $e');
      return [];
    }
  }

  /// Get wards for a specific LGA and state
  /// Filters the wards collection by both state and lga
  Future<List<String>> getWardsForLGA(String state, String lga) async {
    final cacheKey = '$state-$lga';
    
    // Return from cache if available
    if (_wardCache.containsKey(cacheKey)) {
      return _wardCache[cacheKey] ?? [];
    }

    try {
      // Query wards collection for this state and LGA combination
      final snapshot = await _firestore
          .collection('wards')
          .where('state', isEqualTo: state)
          .where('lga', isEqualTo: lga)
          .get();

      Set<String> wards = {};
      for (var doc in snapshot.docs) {
        final ward = doc.data()['ward'] as String?;
        if (ward != null && ward.isNotEmpty) {
          wards.add(ward);
        }
      }

      List<String> wardList = wards.toList()..sort();
      _wardCache[cacheKey] = wardList;
      
      debugPrint('Loaded wards for $state - $lga: $wardList');
      notifyListeners();
      return wardList;
    } catch (e) {
      debugPrint('Error loading wards for $state - $lga: $e');
      return [];
    }
  }

  /// Get all LGAs and wards data for a state (for UI initialization)
  /// Returns a map: {'lga1': ['ward1', 'ward2'], 'lga2': ['ward3', 'ward4']}
  Future<Map<String, List<String>>> getAllLGAsAndWardsForState(String state) async {
    try {
      final snapshot = await _firestore
          .collection('wards')
          .where('state', isEqualTo: state)
          .get();

      Map<String, List<String>> lgaWardsMap = {};
      
      for (var doc in snapshot.docs) {
        final lga = doc.data()['lga'] as String?;
        final ward = doc.data()['ward'] as String?;
        
        if (lga != null && ward != null && lga.isNotEmpty && ward.isNotEmpty) {
          if (!lgaWardsMap.containsKey(lga)) {
            lgaWardsMap[lga] = [];
          }
          if (!lgaWardsMap[lga]!.contains(ward)) {
            lgaWardsMap[lga]!.add(ward);
          }
        }
      }

      // Sort wards for each LGA
      for (var wards in lgaWardsMap.values) {
        wards.sort();
      }

      debugPrint('Loaded ${lgaWardsMap.length} LGAs for state $state');
      return lgaWardsMap;
    } catch (e) {
      debugPrint('Error loading all LGAs and wards for state $state: $e');
      return {};
    }
  }

  /// Clear cache to force fresh fetch from Firestore
  void clearCache() {
    _lgaCache.clear();
    _wardCache.clear();
    debugPrint('Location cache cleared');
    notifyListeners();
  }

  /// Get cached LGAs without making a Firestore query
  List<String> getCachedLGAsForState(String state) {
    return _lgaCache[state] ?? [];
  }

  /// Get cached wards without making a Firestore query
  List<String> getCachedWardsForLGA(String state, String lga) {
    return _wardCache['$state-$lga'] ?? [];
  }

  /// Validate if a ward belongs to an LGA in a state
  Future<bool> isValidWard(String state, String lga, String ward) async {
    try {
      final snapshot = await _firestore
          .collection('wards')
          .where('state', isEqualTo: state)
          .where('lga', isEqualTo: lga)
          .where('ward', isEqualTo: ward)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error validating ward: $e');
      return false;
    }
  }

  @override
  void dispose() {
    clearCache();
    super.dispose();
  }
}
