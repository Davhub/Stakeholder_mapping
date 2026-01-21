import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mapping/model/model.dart';

/// Centralized Firestore service for web admin dashboard
/// All queries are scoped to admin's assigned state for security
class AdminFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current admin's state from Firestore
  Future<String?> getAdminState() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return userDoc.data()?['state'] as String?;
    } catch (e) {
      print('Error fetching admin state: $e');
      return null;
    }
  }

  /// Get admin profile data
  Future<Map<String, dynamic>?> getAdminProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return {
        'email': userDoc.data()?['email'] ?? user.email,
        'state': userDoc.data()?['state'] ?? 'N/A',
        'role': userDoc.data()?['role'] ?? 'Admin',
        'uid': user.uid,
      };
    } catch (e) {
      print('Error fetching admin profile: $e');
      return null;
    }
  }

  /// Get total stakeholders count for admin's state
  Future<int> getTotalStakeholders(String adminState) async {
    try {
      final snapshot = await _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: adminState)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error fetching total stakeholders: $e');
      return 0;
    }
  }

  /// Get unique LGAs count for admin's state
  Future<int> getTotalLGAs(String adminState) async {
    try {
      final snapshot = await _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: adminState)
          .get();

      final uniqueLGAs = snapshot.docs
          .map((doc) => doc.data()['lg'] as String?)
          .where((lg) => lg != null && lg.isNotEmpty)
          .toSet();

      return uniqueLGAs.length;
    } catch (e) {
      print('Error fetching total LGAs: $e');
      return 0;
    }
  }

  /// Get unique wards count for admin's state
  Future<int> getTotalWards(String adminState) async {
    try {
      final snapshot = await _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: adminState)
          .get();

      final uniqueWards = snapshot.docs
          .map((doc) => doc.data()['ward'] as String?)
          .where((ward) => ward != null && ward.isNotEmpty)
          .toSet();

      return uniqueWards.length;
    } catch (e) {
      print('Error fetching total wards: $e');
      return 0;
    }
  }

  /// Get recently added stakeholders (last 7 days)
  Future<int> getRecentlyAddedStakeholders(String adminState) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: adminState)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      // If createdAt field doesn't exist, return 0
      print('Error fetching recently added stakeholders: $e');
      return 0;
    }
  }

  /// Real-time stream of stakeholders for admin's state with pagination
  Stream<QuerySnapshot> getStakeholdersStream({
    required String adminState,
    String? lgaFilter,
    String? wardFilter,
    int limit = 50,
    DocumentSnapshot? startAfter,
    String orderBy = 'fullName',
    bool descending = false,
  }) {
    Query query = _firestore
        .collection('stakeholders')
        .where('state', isEqualTo: adminState);

    if (lgaFilter != null && lgaFilter.isNotEmpty) {
      query = query.where('lg', isEqualTo: lgaFilter);
    }

    if (wardFilter != null && wardFilter.isNotEmpty) {
      query = query.where('ward', isEqualTo: wardFilter);
    }

    query = query.orderBy(orderBy, descending: descending).limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return query.snapshots();
  }

  /// Search stakeholders by name, phone, or association
  Future<List<Stakeholder>> searchStakeholders({
    required String adminState,
    required String searchQuery,
  }) async {
    try {
      if (searchQuery.isEmpty) return [];

      final snapshot = await _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: adminState)
          .get();

      final searchLower = searchQuery.toLowerCase();

      return snapshot.docs
          .map((doc) => Stakeholder.fromFirestore(doc))
          .where((stakeholder) {
        return stakeholder.fullName.toLowerCase().contains(searchLower) ||
            stakeholder.phoneNumber.toLowerCase().contains(searchLower) ||
            stakeholder.association.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      print('Error searching stakeholders: $e');
      return [];
    }
  }

  /// Create new stakeholder
  Future<bool> createStakeholder(Map<String, dynamic> data) async {
    try {
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('stakeholders').add(data);
      return true;
    } catch (e) {
      print('Error creating stakeholder: $e');
      return false;
    }
  }

  /// Update stakeholder
  Future<bool> updateStakeholder(
      String stakeholderId, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('stakeholders')
          .doc(stakeholderId)
          .update(data);
      return true;
    } catch (e) {
      print('Error updating stakeholder: $e');
      return false;
    }
  }

  /// Delete stakeholder
  Future<bool> deleteStakeholder(String stakeholderId) async {
    try {
      await _firestore.collection('stakeholders').doc(stakeholderId).delete();
      return true;
    } catch (e) {
      print('Error deleting stakeholder: $e');
      return false;
    }
  }

  /// Get stakeholder distribution by LGA
  Future<Map<String, int>> getStakeholderDistributionByLGA(
      String adminState) async {
    try {
      final snapshot = await _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: adminState)
          .get();

      final distribution = <String, int>{};
      for (var doc in snapshot.docs) {
        final lg = doc.data()['lg'] as String? ?? 'Unknown';
        distribution[lg] = (distribution[lg] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      print('Error fetching LGA distribution: $e');
      return {};
    }
  }

  /// Get stakeholder distribution by Ward
  Future<Map<String, int>> getStakeholderDistributionByWard(
      String adminState, String? selectedLGA) async {
    try {
      Query query = _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: adminState);

      if (selectedLGA != null && selectedLGA.isNotEmpty) {
        query = query.where('lg', isEqualTo: selectedLGA);
      }

      final snapshot = await query.get();

      final distribution = <String, int>{};
      for (var doc in snapshot.docs) {
        final ward = doc.data() as Map<String, dynamic>;
        final wardName = ward['ward'] as String? ?? 'Unknown';
        distribution[wardName] = (distribution[wardName] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      print('Error fetching ward distribution: $e');
      return {};
    }
  }

  /// Get stakeholder additions over time (last 30 days)
  Future<Map<DateTime, int>> getStakeholderAdditionsTrend(
      String adminState) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: adminState)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final trends = <DateTime, int>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['createdAt'] != null) {
          final timestamp = data['createdAt'] as Timestamp;
          final date = DateTime(timestamp.toDate().year,
              timestamp.toDate().month, timestamp.toDate().day);
          trends[date] = (trends[date] ?? 0) + 1;
        }
      }

      return trends;
    } catch (e) {
      print('Error fetching additions trend: $e');
      return {};
    }
  }

  /// Get list of unique LGAs for admin's state
  Future<List<String>> getUniqueLGAs(String adminState) async {
    try {
      final snapshot = await _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: adminState)
          .get();

      final uniqueLGAs = snapshot.docs
          .map((doc) => doc.data()['lg'] as String?)
          .where((lg) => lg != null && lg.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      uniqueLGAs.sort();
      return uniqueLGAs;
    } catch (e) {
      print('Error fetching unique LGAs: $e');
      return [];
    }
  }

  /// Get list of unique wards for admin's state (optionally filtered by LGA)
  Future<List<String>> getUniqueWards(String adminState, [String? lga]) async {
    try {
      Query query = _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: adminState);

      if (lga != null && lga.isNotEmpty) {
        query = query.where('lg', isEqualTo: lga);
      }

      final snapshot = await query.get();

      final uniqueWards = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['ward'] as String?)
          .where((ward) => ward != null && ward.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      uniqueWards.sort();
      return uniqueWards;
    } catch (e) {
      print('Error fetching unique wards: $e');
      return [];
    }
  }
}
