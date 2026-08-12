import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:impact_konnect/core/utils/location_utils.dart';

// Persist location (state/lga/ward) caches to Hive so they survive app restarts

/// Service to manage states, LGAs, and wards data from Firestore
/// Replaces hardcoded location data with dynamic Firestore queries
class LocationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for locations to minimize Firestore queries
  late Map<String, List<String>> _stateCache;
  late Map<String, List<String>> _lgaCache; // state -> LGAs
  late Map<String, List<String>> _wardCache; // lga -> wards
  
  bool _isInitialized = false;
  static const String _locationsBoxName = 'locations_cache';
  late Box<dynamic> _locationsBox;

  LocationService() {
    _stateCache = {};
    _lgaCache = {};
    _wardCache = {};
  }

  /// Helper to read a string field from a Firestore document using multiple possible keys
  String? _readStringField(Map<String, dynamic> data, List<String> keys) {
    return LocationUtils.readStringField(data, keys);
  }

  String _normalizeLocation(String value) {
    final normalized = LocationUtils.normalizeDisplay(value);
    debugPrint('🧩 Normalized location input "$value" -> "$normalized"');
    return normalized;
  }

  /// Persist current in-memory caches to Hive
  Future<void> _saveCachesToBox() async {
    try {
      if (!Hive.isBoxOpen(_locationsBoxName)) return;
      await _locationsBox.put('lgaCache', _lgaCache);
      await _locationsBox.put('wardCache', _wardCache);
      await _locationsBox.put('stateCache', _stateCache);
      debugPrint('LocationService: caches saved to Hive');
    } catch (e) {
      debugPrint('Error saving location caches to Hive: $e');
    }
  }

  bool get isInitialized => _isInitialized;

  /// Initialize and load all states from Firestore
  Future<void> initialize() async {
    try {
      // Open Hive box for persistence
      try {
        _locationsBox = await Hive.openBox(_locationsBoxName);
        // Load persisted caches if present
        final persistedLga = _locationsBox.get('lgaCache');
        final persistedWard = _locationsBox.get('wardCache');
        final persistedState = _locationsBox.get('stateCache');

        if (persistedLga is Map) {
          // ensure proper typing
          _lgaCache = Map<String, List<String>>.fromEntries(
              persistedLga.entries.map((e) => MapEntry(e.key as String, List<String>.from(e.value))));
        }
        if (persistedWard is Map) {
          _wardCache = Map<String, List<String>>.fromEntries(
              persistedWard.entries.map((e) => MapEntry(e.key as String, List<String>.from(e.value))));
        }
        if (persistedState is Map) {
          _stateCache = Map<String, List<String>>.fromEntries(
              persistedState.entries.map((e) => MapEntry(e.key as String, List<String>.from(e.value))));
        }
      } catch (e) {
        debugPrint('LocationService: could not open Hive box: $e');
      }

      // Ensure we have list of states (either from persisted or fresh)
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
        final data = doc.data();
        final state = _readStringField(data, ['state', 'State']);
        if (state != null && state.isNotEmpty) {
          states.add(_normalizeLocation(state));
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
      debugPrint('🔄 [LGA-QUERY] Cache hit for state: $state');
      return _lgaCache[state] ?? [];
    }

    try {
      debugPrint('🔄 [LGA-QUERY] Fetching LGAs for state: "$state"');

      // First try exact-match query
      final snapshot = await _firestore
          .collection('wards')
          .where('state', isEqualTo: state)
          .get();

      debugPrint('📊 [LGA-DATA] Exact query returned ${snapshot.docs.length} documents for state "$state"');

      Set<String> lgas = {};
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        final lga = _readStringField(data, ['lga', 'LGA', 'lg']);

        // Log each document's LGA field to detect issues
        if (i < 3) {
          debugPrint('   Doc $i: lga="${lga}" (available fields: ${data.keys})');
        }

        if (lga != null && lga.isNotEmpty) {
          lgas.add(_normalizeLocation(lga));
        }
      }

      // Fallback: if exact-match query returned nothing, perform a client-side, case-insensitive filter
      if (lgas.isEmpty) {
        debugPrint('🔁 [LGA-FALLBACK] Exact query returned no LGAs; performing case-insensitive client-side filter');
        final allSnapshot = await _firestore.collection('wards').get();
        for (final doc in allSnapshot.docs) {
          final data = doc.data();
          final docState = _readStringField(data, ['state', 'State']);
          if (docState != null && docState.toLowerCase() == state.toLowerCase()) {
            final lga = _readStringField(data, ['lga', 'LGA', 'lg']);
            if (lga != null && lga.isNotEmpty) lgas.add(_normalizeLocation(lga));
          }
        }
        debugPrint('🔁 [LGA-FALLBACK] Found ${lgas.length} LGAs via fallback');
      }

      List<String> lgaList = lgas.toList()..sort();
      _lgaCache[state] = lgaList;
      // Persist caches
      await _saveCachesToBox();
      debugPrint('✅ [LGA-DATA] Loaded ${lgaList.length} unique LGAs: $lgaList');
      notifyListeners();
      return lgaList;
    } catch (e) {
      debugPrint('❌ [LGA-ERROR] Error loading LGAs for state "$state": $e');
      return [];
    }
  }

  /// Get wards for a specific LGA and state
  /// Filters the wards collection by both state and lga
  Future<List<String>> getWardsForLGA(String state, String lga) async {
    final cacheKey = '$state-$lga';
    
    // Return from cache if available
    if (_wardCache.containsKey(cacheKey)) {
      debugPrint('🔄 [WARD-QUERY] Cache hit for state=$state, lga=$lga');
      return _wardCache[cacheKey] ?? [];
    }

    try {
      debugPrint('🔄 [WARD-QUERY] Fetching wards for state="$state", lga="$lga"');

      // First try exact-match query
      final snapshot = await _firestore
          .collection('wards')
          .where('state', isEqualTo: state)
          .where('lga', isEqualTo: lga)
          .get();

      debugPrint('📊 [WARD-DATA] Exact query returned ${snapshot.docs.length} documents');

      Set<String> wards = {};
      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        final ward = _readStringField(data, ['ward', 'Ward']);

        // Log first few wards
        if (i < 3) {
          debugPrint('   Doc $i: ward="${ward}" (available: ${data.keys})');
        }

        if (ward != null && ward.isNotEmpty) {
          wards.add(_normalizeLocation(ward));
        }
      }

      // Fallback: if no wards found, do case-insensitive client-side filter
      if (wards.isEmpty) {
        debugPrint('🔁 [WARD-FALLBACK] Exact query returned no wards; performing case-insensitive client-side filter');
        final allSnapshot = await _firestore.collection('wards').get();
        for (final doc in allSnapshot.docs) {
          final data = doc.data();
          final docState = _readStringField(data, ['state', 'State']);
          final docLga = _readStringField(data, ['lga', 'LGA', 'lg']);
          if (docState != null && docLga != null &&
              docState.toLowerCase() == state.toLowerCase() &&
              docLga.toLowerCase() == lga.toLowerCase()) {
            final ward = _readStringField(data, ['ward', 'Ward']);
            if (ward != null && ward.isNotEmpty) wards.add(ward);
          }
        }
        debugPrint('🔁 [WARD-FALLBACK] Found ${wards.length} wards via fallback');
      }

      List<String> wardList = wards.toList()..sort();
      _wardCache[cacheKey] = wardList;
      // Persist caches
      await _saveCachesToBox();
      debugPrint('✅ [WARD-DATA] Loaded ${wardList.length} unique wards: $wardList');
      notifyListeners();
      return wardList;
    } catch (e) {
      debugPrint('❌ [WARD-ERROR] Error loading wards for state="$state", lga="$lga": $e');
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
        final data = doc.data();
        final lga = _readStringField(data, ['lga', 'LGA', 'lg']);
        final ward = _readStringField(data, ['ward', 'Ward']);

        if (lga != null && ward != null && lga.isNotEmpty && ward.isNotEmpty) {
          final normalizedLga = _normalizeLocation(lga);
          final normalizedWard = _normalizeLocation(ward);
          if (!lgaWardsMap.containsKey(normalizedLga)) {
            lgaWardsMap[normalizedLga] = [];
          }
          if (!lgaWardsMap[normalizedLga]!.contains(normalizedWard)) {
            lgaWardsMap[normalizedLga]!.add(normalizedWard);
          }
        }
      }

      // Sort wards for each LGA
      for (var wards in lgaWardsMap.values) {
        wards.sort();
      }

      // Populate internal caches and persist
      _lgaCache[state] = lgaWardsMap.keys.toList()..sort();
      for (var entry in lgaWardsMap.entries) {
        _wardCache['$state-${entry.key}'] = List<String>.from(entry.value);
      }
      await _saveCachesToBox();
      debugPrint('Loaded ${lgaWardsMap.length} LGAs for state $state');
      return lgaWardsMap;
    } catch (e) {
      debugPrint('Error loading all LGAs and wards for state $state: $e');
      return {};
    }
  }

  /// Ensure LGAs for a state are loaded in cache (fetches if missing)
  Future<void> ensureLGAsLoadedForState(String state) async {
    if (_lgaCache.containsKey(state) && _lgaCache[state]!.isNotEmpty) return;
    await getLGAsForState(state);
  }

  /// Ensure wards for a state+lga are loaded in cache (fetches if missing)
  Future<void> ensureWardsLoadedForLGA(String state, String lga) async {
    final key = '$state-$lga';
    if (_wardCache.containsKey(key) && _wardCache[key]!.isNotEmpty) return;
    await getWardsForLGA(state, lga);
  }

  /// Clear cache to force fresh fetch from Firestore
  void clearCache() {
    _lgaCache.clear();
    _wardCache.clear();
    debugPrint('Location cache cleared');
    try {
      if (Hive.isBoxOpen(_locationsBoxName)) {
        _locationsBox.clear();
      }
    } catch (e) {
      debugPrint('Error clearing Hive location cache: $e');
    }
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
