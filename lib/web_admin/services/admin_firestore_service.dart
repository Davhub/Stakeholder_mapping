import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:risdi/model/model.dart';
import 'package:risdi/core/utils/location_utils.dart';
import 'package:risdi/web_admin/models/dashboard_models.dart';

/// Centralized Firestore service for web admin dashboard
/// All queries are scoped to admin's assigned state for security
class AdminFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Reads the LGA field regardless of which casing variant a document was
  /// written with ('LGA', 'lg', or 'lga'), and normalizes casing so
  /// "Ibadan North" and "ibadan north" are counted as the same LGA.
  String? _readLga(Map<String, dynamic> data) {
    final raw = LocationUtils.readStringField(data, ['LGA', 'lg', 'lga']);
    if (raw == null || raw.trim().isEmpty) return null;
    return LocationUtils.normalizeDisplay(raw);
  }

  /// Reads the Ward field regardless of casing variant, normalized the same
  /// way as [_readLga].
  String? _readWard(Map<String, dynamic> data) {
    final raw = LocationUtils.readStringField(data, ['ward', 'Ward']);
    if (raw == null || raw.trim().isEmpty) return null;
    return LocationUtils.normalizeDisplay(raw);
  }

  /// Get current admin's state from Firestore
  Future<String?> getAdminState() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      return userDoc.data()?['state'] as String?;
    } catch (e) {
      debugPrint('Error fetching admin state: $e');
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
      debugPrint('Error fetching admin profile: $e');
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
      debugPrint('Error fetching total stakeholders: $e');
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
          .map((doc) => _readLga(doc.data()))
          .whereType<String>()
          .toSet();

      return uniqueLGAs.length;
    } catch (e) {
      debugPrint('Error fetching total LGAs: $e');
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
          .map((doc) => _readWard(doc.data()))
          .whereType<String>()
          .toSet();

      return uniqueWards.length;
    } catch (e) {
      debugPrint('Error fetching total wards: $e');
      return 0;
    }
  }

  /// One-time maintenance: stamps createdAt/updatedAt on stakeholder
  /// documents in the admin's state that don't have a createdAt yet
  /// (e.g. records added by the mobile app before it began writing
  /// timestamps). The true original creation time can't be recovered, so
  /// "now" is used as an approximation. Never touches documents that
  /// already have createdAt set. Returns the number of documents updated.
  Future<int> backfillMissingTimestamps(String adminState) async {
    final snapshot = await _firestore
        .collection('stakeholders')
        .where('state', isEqualTo: adminState)
        .get();

    final missing = snapshot.docs
        .where((doc) => !doc.data().containsKey('createdAt'))
        .toList();

    const chunkSize = 450; // stay under Firestore's 500-write batch limit
    for (var i = 0; i < missing.length; i += chunkSize) {
      final chunk = missing.skip(i).take(chunkSize);
      final batch = _firestore.batch();
      for (final doc in chunk) {
        batch.update(doc.reference, {
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }

    return missing.length;
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
      debugPrint('Error fetching recently added stakeholders: $e');
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
      query = query.where('LGA', isEqualTo: lgaFilter);
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
      debugPrint('Error searching stakeholders: $e');
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
      debugPrint('Error creating stakeholder: $e');
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
      debugPrint('Error updating stakeholder: $e');
      return false;
    }
  }

  /// Delete stakeholder
  Future<bool> deleteStakeholder(String stakeholderId) async {
    try {
      await _firestore.collection('stakeholders').doc(stakeholderId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting stakeholder: $e');
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
        final lg = _readLga(doc.data()) ?? 'Unknown';
        distribution[lg] = (distribution[lg] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      debugPrint('Error fetching LGA distribution: $e');
      return {};
    }
  }

  /// Get stakeholder distribution by Ward
  Future<Map<String, int>> getStakeholderDistributionByWard(
      String adminState, String? selectedLGA) async {
    try {
      final snapshot = await _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: adminState)
          .get();

      final normalizedLgaFilter = (selectedLGA != null && selectedLGA.isNotEmpty)
          ? LocationUtils.normalizeDisplay(selectedLGA)
          : null;

      final distribution = <String, int>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (normalizedLgaFilter != null && _readLga(data) != normalizedLgaFilter) {
          continue;
        }
        final wardName = _readWard(data) ?? 'Unknown';
        distribution[wardName] = (distribution[wardName] ?? 0) + 1;
      }

      return distribution;
    } catch (e) {
      debugPrint('Error fetching ward distribution: $e');
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
      debugPrint('Error fetching additions trend: $e');
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

      final uniqueLGAs =
          snapshot.docs.map((doc) => _readLga(doc.data())).whereType<String>().toSet().toList();

      uniqueLGAs.sort();
      return uniqueLGAs;
    } catch (e) {
      debugPrint('Error fetching unique LGAs: $e');
      return [];
    }
  }

  /// Get contact-engagement analytics for the DUA report: which
  /// stakeholders are contacted most (phone call / WhatsApp taps from the
  /// mobile app), and which LGAs/Wards generate the most contact activity.
  Future<DUAContactAnalytics> getContactAnalytics(String adminState) async {
    try {
      final snapshot = await _firestore
          .collection('activity_events')
          .where('eventType', isEqualTo: 'stakeholder.contacted')
          .get();

      final perStakeholder = <String, _StakeholderContactTotals>{};
      final contactsByLGA = <String, int>{};
      final contactsByWard = <String, int>{};

      for (final doc in snapshot.docs) {
        final metadata = doc.data()['metadata'] as Map<String, dynamic>?;
        if (metadata == null) continue;
        if (metadata['state'] != adminState) continue;

        final stakeholderId = metadata['stakeholderId'] as String? ?? '';
        final stakeholderName = metadata['stakeholderName'] as String? ?? '';
        final contactMethod = metadata['contactMethod'] as String? ?? '';
        final lg = metadata['lg'] as String? ?? 'Unknown';
        final ward = metadata['ward'] as String? ?? 'Unknown';
        if (stakeholderId.isEmpty) continue;

        final totals = perStakeholder.putIfAbsent(
          stakeholderId,
          () => _StakeholderContactTotals(
            name: stakeholderName,
            lg: lg,
            ward: ward,
          ),
        );
        totals.total++;
        if (contactMethod == 'call') {
          totals.calls++;
        } else if (contactMethod == 'whatsapp') {
          totals.whatsapp++;
        }

        contactsByLGA[lg] = (contactsByLGA[lg] ?? 0) + 1;
        contactsByWard[ward] = (contactsByWard[ward] ?? 0) + 1;
      }

      final topContacted = perStakeholder.values.toList()
        ..sort((a, b) => b.total.compareTo(a.total));

      return DUAContactAnalytics(
        topContactedStakeholders: topContacted
            .take(10)
            .map((t) => ContactedStakeholder(
                  name: t.name,
                  lg: t.lg,
                  ward: t.ward,
                  totalContacts: t.total,
                  calls: t.calls,
                  whatsapp: t.whatsapp,
                ))
            .toList(),
        contactsByLGA: contactsByLGA,
        contactsByWard: contactsByWard,
      );
    } catch (e) {
      debugPrint('Error fetching contact analytics: $e');
      return DUAContactAnalytics(
        topContactedStakeholders: [],
        contactsByLGA: {},
        contactsByWard: {},
      );
    }
  }

  /// Get list of unique wards for admin's state (optionally filtered by LGA)
  Future<List<String>> getUniqueWards(String adminState, [String? lga]) async {
    try {
      final snapshot = await _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: adminState)
          .get();

      final normalizedLgaFilter =
          (lga != null && lga.isNotEmpty) ? LocationUtils.normalizeDisplay(lga) : null;

      final uniqueWards = snapshot.docs
          .map((doc) => doc.data())
          .where((data) =>
              normalizedLgaFilter == null || _readLga(data) == normalizedLgaFilter)
          .map((data) => _readWard(data))
          .whereType<String>()
          .toSet()
          .toList();

      uniqueWards.sort();
      return uniqueWards;
    } catch (e) {
      debugPrint('Error fetching unique wards: $e');
      return [];
    }
  }
}

/// Accumulator used by [AdminFirestoreService.getContactAnalytics] while
/// aggregating raw activity events into per-stakeholder totals.
class _StakeholderContactTotals {
  final String name;
  final String lg;
  final String ward;
  int total = 0;
  int calls = 0;
  int whatsapp = 0;

  _StakeholderContactTotals({
    required this.name,
    required this.lg,
    required this.ward,
  });
}
