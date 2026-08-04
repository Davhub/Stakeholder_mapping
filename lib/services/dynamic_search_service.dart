import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:risdi/core/utils/location_utils.dart';
import 'package:risdi/model/model.dart';
import 'location_service.dart';

/// Enhanced search and filtering service that works with dynamic location data
/// Provides simultaneous filtering: State -> LGA -> Ward -> Search results
class DynamicSearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService;

  DynamicSearchService(this._locationService);

  /// Fetch stakeholders with combined filters (state, LGA, ward, search query)
  /// Works simultaneously: selecting LGA filters available wards
  Future<List<Stakeholder>> searchStakeholders({
    required String state,
    String? lga,
    String? ward,
    String? searchQuery,
  }) async {
    try {
      final normalizedState = LocationUtils.normalizeDisplay(state);
      final normalizedLga = lga != null ? LocationUtils.normalizeDisplay(lga) : null;
      final normalizedWard = ward != null ? LocationUtils.normalizeDisplay(ward) : null;

      final snapshot = await _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: normalizedState)
          .get();

      List<Stakeholder> stakeholders = snapshot.docs
          .map((doc) => Stakeholder.fromFirestore(doc))
          .where((stakeholder) {
            if (normalizedLga != null && normalizedLga.isNotEmpty &&
                !LocationUtils.equalsIgnoreCase(stakeholder.lg, normalizedLga)) {
              return false;
            }
            if (normalizedWard != null && normalizedWard.isNotEmpty &&
                !LocationUtils.equalsIgnoreCase(stakeholder.ward, normalizedWard)) {
              return false;
            }
            return true;
          })
          .toList();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        stakeholders = stakeholders.where((stakeholder) {
          return stakeholder.fullName.toLowerCase().contains(lowerQuery) ||
              stakeholder.association.toLowerCase().contains(lowerQuery) ||
              stakeholder.lg.toLowerCase().contains(lowerQuery) ||
              stakeholder.ward.toLowerCase().contains(lowerQuery) ||
              stakeholder.phoneNumber.toLowerCase().contains(lowerQuery);
        }).toList();
      }

      return stakeholders;
    } catch (e) {
      debugPrint('Error searching stakeholders: $e');
      return [];
    }
  }

  /// Get available wards when LGA is selected
  /// This enables simultaneous filtering: LGA change -> update ward dropdown
  Future<List<String>> getAvailableWards({
    required String state,
    required String lga,
  }) async {
    try {
      return await _locationService.getWardsForLGA(state, lga);
    } catch (e) {
      debugPrint('Error fetching wards: $e');
      return [];
    }
  }

  /// Get available LGAs for a state
  Future<List<String>> getAvailableLGAs(String state) async {
    try {
      return await _locationService.getLGAsForState(state);
    } catch (e) {
      debugPrint('Error fetching LGAs: $e');
      return [];
    }
  }

  /// Stream for real-time stakeholder updates with filters
  /// Useful for live search results
  Stream<List<Stakeholder>> streamStakeholders({
    required String state,
    String? lga,
    String? ward,
  }) {
    try {
      final normalizedState = LocationUtils.normalizeDisplay(state);
      final normalizedLga = lga != null ? LocationUtils.normalizeDisplay(lga) : null;
      final normalizedWard = ward != null ? LocationUtils.normalizeDisplay(ward) : null;

      return _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: normalizedState)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => Stakeholder.fromFirestore(doc))
                .where((stakeholder) {
                  if (normalizedLga != null && normalizedLga.isNotEmpty &&
                      !LocationUtils.equalsIgnoreCase(stakeholder.lg, normalizedLga)) {
                    return false;
                  }
                  if (normalizedWard != null && normalizedWard.isNotEmpty &&
                      !LocationUtils.equalsIgnoreCase(stakeholder.ward, normalizedWard)) {
                    return false;
                  }
                  return true;
                })
                .toList();
          });
    } catch (e) {
      debugPrint('Error streaming stakeholders: $e');
      return Stream.value([]);
    }
  }

  /// Get stakeholder count for a specific filter combination
  Future<int> getStakeholderCount({
    required String state,
    String? lga,
    String? ward,
  }) async {
    try {
      final normalizedState = LocationUtils.normalizeDisplay(state);
      final normalizedLga = lga != null ? LocationUtils.normalizeDisplay(lga) : null;
      final normalizedWard = ward != null ? LocationUtils.normalizeDisplay(ward) : null;

      final snapshot = await _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: normalizedState)
          .get();

      return snapshot.docs.where((doc) {
        final stakeholder = Stakeholder.fromFirestore(doc);
        if (normalizedLga != null && normalizedLga.isNotEmpty &&
            !LocationUtils.equalsIgnoreCase(stakeholder.lg, normalizedLga)) {
          return false;
        }
        if (normalizedWard != null && normalizedWard.isNotEmpty &&
            !LocationUtils.equalsIgnoreCase(stakeholder.ward, normalizedWard)) {
          return false;
        }
        return true;
      }).length;
    } catch (e) {
      debugPrint('Error counting stakeholders: $e');
      return 0;
    }
  }

  /// Get all available LGAs and wards for a state (for bulk UI initialization)
  Future<Map<String, List<String>>> getLGAsAndWardsMap(String state) async {
    try {
      return await _locationService.getAllLGAsAndWardsForState(state);
    } catch (e) {
      debugPrint('Error fetching LGAs and wards map: $e');
      return {};
    }
  }
}
