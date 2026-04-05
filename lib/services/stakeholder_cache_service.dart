import 'package:hive/hive.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:risdi/model/stakeholder_contact_model.dart';

/// Service for managing Stakeholder caching with Hive
/// Provides fast local-first data retrieval with background Firestore sync
class StakeholderCacheService {
  static final StakeholderCacheService _instance =
      StakeholderCacheService._internal();
  static const String _stakeholdersBoxName = 'stakeholders';
  static const String _favoritesBoxName = 'favorites';
  static const String _cacheTimestampKey = 'cache_timestamp';

  late Box<Stakeholder> _stakeholdersBox;
  late Box<dynamic> _favoritesBox;
  bool _initialized = false;

  factory StakeholderCacheService() {
    return _instance;
  }

  StakeholderCacheService._internal();

  /// Initialize the cache service - must be called before using any methods
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Open boxes
      _stakeholdersBox = await Hive.openBox<Stakeholder>(_stakeholdersBoxName);
      _favoritesBox = await Hive.openBox(_favoritesBoxName);
      _initialized = true;
      print('StakeholderCacheService initialized successfully');
    } catch (e) {
      print('Error initializing StakeholderCacheService: $e');
      rethrow;
    }
  }

  /// Get all cached stakeholders
  List<Stakeholder> getAllStakeholders() {
    if (!_initialized) {
      print('Warning: Cache service not initialized');
      return [];
    }
    return _stakeholdersBox.values.toList();
  }

  /// Get stakeholders by state - INSTANT from cache
  List<Stakeholder> getStakeholdersByState(String state) {
    if (!_initialized) return [];
    return _stakeholdersBox.values.where((s) => s.state == state).toList();
  }

  /// Get stakeholder by name
  Stakeholder? getStakeholderByName(String fullName) {
    if (!_initialized) return null;
    try {
      return _stakeholdersBox.values.firstWhere(
        (s) => s.fullName.toLowerCase() == fullName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Search stakeholders by multiple criteria - INSTANT from cache
  List<Stakeholder> searchStakeholders({
    required String query,
    String? state,
    String? association,
    String? lg,
    String? ward,
  }) {
    if (!_initialized) return [];

    List<Stakeholder> results = _stakeholdersBox.values.where((s) {
      // Check state filter
      if (state != null && state.isNotEmpty && s.state != state) {
        return false;
      }

      // Check association filter
      if (association != null &&
          association.isNotEmpty &&
          s.association != association) {
        return false;
      }

      // Check LG filter
      if (lg != null && lg.isNotEmpty && s.lg != lg) {
        return false;
      }

      // Check ward filter
      if (ward != null && ward.isNotEmpty && s.ward != ward) {
        return false;
      }

      // Check query match (name, phone, email)
      final queryLower = query.toLowerCase();
      return s.fullName.toLowerCase().contains(queryLower) ||
          s.phoneNumber.toLowerCase().contains(queryLower) ||
          s.email.toLowerCase().contains(queryLower) ||
          s.association.toLowerCase().contains(queryLower);
    }).toList();

    return results;
  }

  /// Cache stakeholders from Firestore
  Future<void> cacheStakeholders(List<Stakeholder> stakeholders) async {
    if (!_initialized) return;

    try {
      await _stakeholdersBox.clear();
      await _stakeholdersBox.addAll(stakeholders);

      // Update cache timestamp
      await _favoritesBox.put(_cacheTimestampKey, DateTime.now().toString());

      print('Cached ${stakeholders.length} stakeholders');
    } catch (e) {
      print('Error caching stakeholders: $e');
    }
  }

  /// Add single stakeholder to cache
  Future<void> addStakeholderToCache(Stakeholder stakeholder) async {
    if (!_initialized) return;
    try {
      await _stakeholdersBox.add(stakeholder);
    } catch (e) {
      print('Error adding stakeholder to cache: $e');
    }
  }

  /// Update single stakeholder in cache
  Future<void> updateStakeholderInCache(
    String fullName,
    Stakeholder updatedStakeholder,
  ) async {
    if (!_initialized) return;

    try {
      final index = _stakeholdersBox.values.toList().indexWhere(
            (s) => s.fullName.toLowerCase() == fullName.toLowerCase(),
          );

      if (index != -1) {
        await _stakeholdersBox.putAt(index, updatedStakeholder);
      }
    } catch (e) {
      print('Error updating stakeholder in cache: $e');
    }
  }

  /// Clear all cached stakeholders
  Future<void> clearCache() async {
    if (!_initialized) return;
    try {
      await _stakeholdersBox.clear();
      print('Cache cleared');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Get cache size
  int getCacheSize() {
    if (!_initialized) return 0;
    return _stakeholdersBox.length;
  }

  /// Check if cache is populated
  bool isCachePopulated() {
    if (!_initialized) return false;
    return _stakeholdersBox.isNotEmpty;
  }

  // ============ FAVORITES MANAGEMENT ============

  /// Add stakeholder to favorites (persisted in Hive)
  Future<void> addFavorite(String stakeholderName) async {
    if (!_initialized) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final favKey = '${userId}_${stakeholderName}';
      await _favoritesBox.put(favKey, {
        'name': stakeholderName,
        'addedAt': DateTime.now().toIso8601String(),
      });
      print('Added $stakeholderName to favorites');
    } catch (e) {
      print('Error adding favorite: $e');
    }
  }

  /// Remove stakeholder from favorites
  Future<void> removeFavorite(String stakeholderName) async {
    if (!_initialized) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final favKey = '${userId}_${stakeholderName}';
      await _favoritesBox.delete(favKey);
      print('Removed $stakeholderName from favorites');
    } catch (e) {
      print('Error removing favorite: $e');
    }
  }

  /// Check if stakeholder is in favorites (INSTANT check)
  bool isFavorite(String stakeholderName) {
    if (!_initialized) return false;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final favKey = '${userId}_${stakeholderName}';
      return _favoritesBox.containsKey(favKey);
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }

  /// Get all favorites for current user
  List<String> getAllFavorites() {
    if (!_initialized) return [];

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final favoritedNames = <String>[];

      for (final key in _favoritesBox.keys) {
        if (key.toString().startsWith('${userId}_')) {
          final name = key.toString().substring('${userId}_'.length);
          favoritedNames.add(name);
        }
      }

      return favoritedNames;
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  /// Clear all favorites for current user
  Future<void> clearFavorites() async {
    if (!_initialized) return;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final keysToDelete = <String>[];

      for (final key in _favoritesBox.keys) {
        if (key.toString().startsWith('${userId}_')) {
          keysToDelete.add(key.toString());
        }
      }

      for (final key in keysToDelete) {
        await _favoritesBox.delete(key);
      }

      print('Cleared ${keysToDelete.length} favorites');
    } catch (e) {
      print('Error clearing favorites: $e');
    }
  }

  /// Get the number of favorites
  int getFavoritesCount() {
    if (!_initialized) return 0;

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      var count = 0;

      for (final key in _favoritesBox.keys) {
        if (key.toString().startsWith('${userId}_')) {
          count++;
        }
      }

      return count;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }
}
