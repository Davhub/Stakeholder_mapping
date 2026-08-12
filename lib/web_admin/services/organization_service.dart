import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// An organization: the tenant boundary every user and stakeholder record
/// belongs to. Kept intentionally minimal for now - name and provenance
/// only. Fields for the public registration/approval workflow (contact
/// person, phone, country, approval status) are a later phase; this shape
/// only needs to support tagging existing data for traceability today.
class Organization {
  final String id;
  final String name;
  final DateTime? createdAt;
  final String? createdBy;

  Organization({
    required this.id,
    required this.name,
    this.createdAt,
    this.createdBy,
  });

  factory Organization.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawCreatedAt = data['createdAt'];
    return Organization(
      id: doc.id,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Unnamed organization',
      createdAt: rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null,
      createdBy: data['createdBy'] as String?,
    );
  }
}

class OrganizationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _organizations =>
      _firestore.collection('organizations');

  /// The signed-in user's own organizationId, or null if their profile
  /// document doesn't have one yet (e.g. pre-migration accounts before
  /// this feature shipped).
  Future<String?> getMyOrganizationId() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc =
          await _firestore.collection('users').doc(user.uid).get();
      final orgId = doc.data()?['organizationId'];
      return (orgId is String && orgId.trim().isNotEmpty)
          ? orgId.trim()
          : null;
    } catch (e) {
      debugPrint('getMyOrganizationId failed: $e');
      return null;
    }
  }

  Future<Organization?> getOrganization(String organizationId) async {
    try {
      final doc = await _organizations.doc(organizationId).get();
      if (!doc.exists) return null;
      return Organization.fromDoc(doc);
    } catch (e) {
      debugPrint('getOrganization failed: $e');
      return null;
    }
  }

  Stream<List<Organization>> streamOrganizations() {
    return _organizations.snapshots().map(
          (snap) => snap.docs.map(Organization.fromDoc).toList()
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())),
        );
  }

  Future<String?> createOrganization(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    try {
      final doc = await _organizations.add({
        'name': trimmed,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.email ?? 'unknown',
      });
      return doc.id;
    } catch (e) {
      debugPrint('createOrganization failed: $e');
      return null;
    }
  }
}
