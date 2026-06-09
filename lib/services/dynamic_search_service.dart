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

      Query query = _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: normalizedState);

      // Add LGA filter if selected
      if (normalizedLga != null && normalizedLga.isNotEmpty) {
        query = query.where('LGA', isEqualTo: normalizedLga);
      }

      // Add ward filter if selected
      if (normalizedWard != null && normalizedWard.isNotEmpty) {
        query = query.where('ward', isEqualTo: normalizedWard);
      }

      final snapshot = await query.get();
      List<Stakeholder> stakeholders = snapshot.docs
          .map((doc) => Stakeholder.fromFirestore(doc))
          .toList();

      if (stakeholders.isEmpty && (normalizedLga?.isNotEmpty == true || normalizedWard?.isNotEmpty == true)) {
        final fallbackSnapshot = await _firestore
            .collection('stakeholders')
            .where('state', isEqualTo: normalizedState)
            .get();
        stakeholders = fallbackSnapshot.docs
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
        }).toList();
      }

      // Apply search query filter if provided
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
      print('Error searching stakeholders: $e');
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
      print('Error fetching wards: $e');
      return [];
    }
  }

  /// Get available LGAs for a state
  Future<List<String>> getAvailableLGAs(String state) async {
    try {
      return await _locationService.getLGAsForState(state);
    } catch (e) {
      print('Error fetching LGAs: $e');
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

      Query query = _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: normalizedState);

      if (normalizedLga != null && normalizedLga.isNotEmpty) {
        query = query.where('LGA', isEqualTo: normalizedLga);
      }

      if (normalizedWard != null && normalizedWard.isNotEmpty) {
        query = query.where('ward', isEqualTo: normalizedWard);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => Stakeholder.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error streaming stakeholders: $e');
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

      Query query = _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: normalizedState);

      if (normalizedLga != null && normalizedLga.isNotEmpty) {
        query = query.where('LGA', isEqualTo: normalizedLga);
      }

      if (normalizedWard != null && normalizedWard.isNotEmpty) {
        query = query.where('ward', isEqualTo: normalizedWard);
      }

      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error counting stakeholders: $e');
      return 0;
    }
  }

  /// Get all available LGAs and wards for a state (for bulk UI initialization)
  Future<Map<String, List<String>>> getLGAsAndWardsMap(String state) async {
    try {
      return await _locationService.getAllLGAsAndWardsForState(state);
    } catch (e) {
      print('Error fetching LGAs and wards map: $e');
      return {};
    }
  }
}
