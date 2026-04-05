import 'package:flutter/material.dart';
import 'package:risdi/model/model.dart';
import 'package:risdi/services/stakeholder_cache_service.dart';
import 'package:risdi/model/stakeholder_contact_model.dart';
import 'package:risdi/services/stakeholder_cache_service.dart';

/// Global app state service to prevent unnecessary reloads
/// Maintains in-memory cache of dashboard data and favorites
class AppStateService extends ChangeNotifier {
  static final AppStateService _instance = AppStateService._internal();

  factory AppStateService() {
    return _instance;
  }

  AppStateService._internal();

  // Cached data
  String? _userState;
  List<Stakeholder> _allStakeholders = [];
  int _favoritesCount = 0;
  bool _isInitialized = false;

  // Getters
  String? get userState => _userState;
  List<Stakeholder> get allStakeholders => _allStakeholders;
  int get favoritesCount => _favoritesCount;
  bool get isInitialized => _isInitialized;

  /// Initialize app state with user state and cache data
  Future<void> initialize(String userState) async {
    if (_isInitialized && _userState == userState) {
      return; // Already initialized for this user state
    }

    _userState = userState;

    // Load stakeholders from cache
    final cacheService = StakeholderCacheService();
    _allStakeholders = cacheService.getStakeholdersByState(userState);

    // Load favorites count
    _favoritesCount = cacheService.getFavoritesCount();

    _isInitialized = true;
    notifyListeners();
  }

  /// Update stakeholders in memory cache
  void updateStakeholders(List<Stakeholder> stakeholders) {
    _allStakeholders = stakeholders;
    notifyListeners();
  }

  /// Increment favorites count
  void incrementFavoritesCount() {
    _favoritesCount++;
    notifyListeners();
  }

  /// Decrement favorites count
  void decrementFavoritesCount() {
    if (_favoritesCount > 0) {
      _favoritesCount--;
    }
    notifyListeners();
  }

  /// Set favorites count directly
  void setFavoritesCount(int count) {
    _favoritesCount = count;
    notifyListeners();
  }

  /// Reset state (on logout)
  void reset() {
    _userState = null;
    _allStakeholders = [];
    _favoritesCount = 0;
    _isInitialized = false;
    notifyListeners();
  }
}
