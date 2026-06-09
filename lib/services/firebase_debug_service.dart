import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive diagnostic service for debugging Firestore data consistency issues
/// Run this to identify state mismatches, field name problems, and empty collections
class FirebaseDebugService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Run complete system diagnostic
  /// Returns diagnostic report with all findings
  Future<String> runCompleteDiagnostic() async {
    final report = StringBuffer();
    report.writeln('╔═══════════════════════════════════════════════════════════════╗');
    report.writeln('║  FIREBASE SYSTEM DIAGNOSTIC - ${DateTime.now().toString().substring(0, 19)}');
    report.writeln('╚═══════════════════════════════════════════════════════════════╝\n');

    // Step 1: User Authentication
    report.writeln('🔐 STEP 1: AUTHENTICATION CHECK');
    report.writeln('─' * 65);
    final userDiag = await _checkUserAuth();
    report.writeln(userDiag);

    // Step 2: User State Consistency
    report.writeln('\n📍 STEP 2: USER STATE CONSISTENCY');
    report.writeln('─' * 65);
    final stateDiag = await _checkUserStateConsistency();
    report.writeln(stateDiag);

    // Step 3: Wards Collection Structure
    report.writeln('\n🏘️  STEP 3: WARDS COLLECTION STRUCTURE');
    report.writeln('─' * 65);
    final wardsDiag = await _checkWardsCollection();
    report.writeln(wardsDiag);

    // Step 4: Stakeholders Collection Structure
    report.writeln('\n👥 STEP 4: STAKEHOLDERS COLLECTION STRUCTURE');
    report.writeln('─' * 65);
    final stakeholdersDiag = await _checkStakeholdersCollection();
    report.writeln(stakeholdersDiag);

    // Step 5: Field Name Consistency
    report.writeln('\n📋 STEP 5: FIELD NAME CONSISTENCY ANALYSIS');
    report.writeln('─' * 65);
    final fieldDiag = await _checkFieldNameConsistency();
    report.writeln(fieldDiag);

    // Step 6: Query Testing
    report.writeln('\n🔍 STEP 6: QUERY TESTING');
    report.writeln('─' * 65);
    final queryDiag = await _testQueries();
    report.writeln(queryDiag);

    report.writeln('\n' + ('═' * 65));
    report.writeln('END OF DIAGNOSTIC REPORT');
    report.writeln('=' * 65);

    return report.toString();
  }

  /// Check user authentication and get user details
  Future<String> _checkUserAuth() async {
    final buf = StringBuffer();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        buf.writeln('❌ No user logged in');
        return buf.toString();
      }

      buf.writeln('✅ User logged in');
      buf.writeln('   UID: ${user.uid}');
      buf.writeln('   Email: ${user.email}');
      buf.writeln('   Display Name: ${user.displayName ?? "Not set"}');
    } catch (e) {
      buf.writeln('❌ Error checking auth: $e');
    }
    return buf.toString();
  }

  /// Check user state from Firestore and compare with wards collection
  Future<String> _checkUserStateConsistency() async {
    final buf = StringBuffer();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        buf.writeln('❌ No user logged in - cannot check state');
        return buf.toString();
      }

      // Get user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        buf.writeln('❌ User document does not exist in Firestore');
        buf.writeln('   UID: ${user.uid}');
        return buf.toString();
      }

      final userData = userDoc.data()!;
      final userState = userData['state'] as String?;
      buf.writeln('✅ User document found');
      buf.writeln('   Fields: ${userData.keys.toList()}');
      buf.writeln('   State: "$userState" (type: ${userState.runtimeType})');

      if (userState == null || userState.isEmpty) {
        buf.writeln('   ⚠️  WARNING: State is null or empty!');
        return buf.toString();
      }

      // Check if this state exists in wards collection
      final wardsSnapshot = await _firestore
          .collection('wards')
          .where('state', isEqualTo: userState)
          .limit(1)
          .get();

      if (wardsSnapshot.docs.isEmpty) {
        buf.writeln('   ❌ CRITICAL: No wards found for state "$userState"');
        buf.writeln('      This explains empty dropdowns!');
      } else {
        buf.writeln('   ✅ State "$userState" found in wards collection');
      }
    } catch (e) {
      buf.writeln('❌ Error checking user state: $e');
    }
    return buf.toString();
  }

  /// Check wards collection structure and data
  Future<String> _checkWardsCollection() async {
    final buf = StringBuffer();
    try {
      final snapshot = await _firestore.collection('wards').limit(5).get();

      if (snapshot.docs.isEmpty) {
        buf.writeln('❌ CRITICAL: Wards collection is EMPTY!');
        buf.writeln('   This is the root cause of empty LGA/Ward dropdowns.');
        return buf.toString();
      }

      buf.writeln('✅ Wards collection has data');
      buf.writeln('   Total documents (first 5): ${snapshot.docs.length}');

      // Analyze first document to understand structure
      final firstDoc = snapshot.docs.first;
      final data = firstDoc.data();
      buf.writeln('\n   Sample Document:');
      buf.writeln('   ID: ${firstDoc.id}');
      buf.writeln('   Fields: ${data.keys.toList()}');

      for (final key in data.keys) {
        final value = data[key];
        final strValue = value is String ? '"$value"' : value;
        buf.writeln('     - $key: $strValue (type: ${value.runtimeType})');
      }

      // Count unique states
      final allDocs = await _firestore.collection('wards').get();
      final states = <String>{};
      for (final doc in allDocs.docs) {
        final state = doc['state'] as String?;
        if (state != null) states.add(state);
      }

      buf.writeln('\n   Unique states in wards collection:');
      for (final state in states.toList()..sort()) {
        buf.writeln('     • "$state"');
      }
    } catch (e) {
      buf.writeln('❌ Error checking wards collection: $e');
    }
    return buf.toString();
  }

  /// Check stakeholders collection structure
  Future<String> _checkStakeholdersCollection() async {
    final buf = StringBuffer();
    try {
      final snapshot = await _firestore.collection('stakeholders').limit(3).get();

      if (snapshot.docs.isEmpty) {
        buf.writeln('⚠️  Stakeholders collection is empty or has no documents');
        return buf.toString();
      }

      buf.writeln('✅ Stakeholders collection has data');
      buf.writeln('   Sample documents count: ${snapshot.docs.length}');

      // Analyze first document
      final firstDoc = snapshot.docs.first;
      final data = firstDoc.data();
      buf.writeln('\n   Sample Document:');
      buf.writeln('   ID: ${firstDoc.id}');
      buf.writeln('   Fields: ${data.keys.toList()}');

      // Check for field names: lg vs lga
      final hasLg = data.containsKey('lg');
      final hasLga = data.containsKey('lga');
      buf.writeln('\n   Field Name Analysis:');
      buf.writeln('     - Has "lg" field: $hasLg');
      buf.writeln('     - Has "lga" field: $hasLga');

      if (!hasLg && !hasLga) {
        buf.writeln('     ⚠️  WARNING: Neither "lg" nor "lga" field found!');
      }

      // Show actual values
      for (final key in ['state', 'lg', 'lga', 'ward', 'name']) {
        if (data.containsKey(key)) {
          final value = data[key];
          final strValue = value is String ? '"$value"' : value;
          buf.writeln('     • $key: $strValue');
        }
      }
    } catch (e) {
      buf.writeln('❌ Error checking stakeholders collection: $e');
    }
    return buf.toString();
  }

  /// Analyze field name consistency between collections
  Future<String> _checkFieldNameConsistency() async {
    final buf = StringBuffer();
    try {
      final wardDoc = await _firestore.collection('wards').limit(1).get();
      final stakDoc = await _firestore.collection('stakeholders').limit(1).get();

      if (wardDoc.docs.isEmpty || stakDoc.docs.isEmpty) {
        buf.writeln('⚠️  Cannot analyze - one or both collections are empty');
        return buf.toString();
      }

      final wardData = wardDoc.docs.first.data();
      final stakData = stakDoc.docs.first.data();

      buf.writeln('Field Name Mapping Analysis:');
      buf.writeln('\n   Wards collection fields: ${wardData.keys.toList()}');
      buf.writeln('   Stakeholders collection fields: ${stakData.keys.toList()}');

      buf.writeln('\n   🔍 Key Field Comparison:');

      // Compare LGA field
      final wardLga = wardData['lga'];
      final stakLg = stakData['lg'];
      buf.writeln('\n     LGA Field:');
      buf.writeln('       Wards uses: "lga" = "$wardLga"');
      buf.writeln('       Stakeholders uses: "lg" = "$stakLg"');
      if (wardLga == stakLg) {
        buf.writeln('       ✅ Values match');
      } else {
        buf.writeln('       ❌ VALUES DO NOT MATCH!');
      }

      // Compare state field
      final wardState = wardData['state'];
      final stakState = stakData['state'];
      buf.writeln('\n     State Field:');
      buf.writeln('       Wards: "state" = "$wardState"');
      buf.writeln('       Stakeholders: "state" = "$stakState"');
      if (wardState == stakState) {
        buf.writeln('       ✅ Values match');
      } else {
        buf.writeln('       ⚠️  Values differ (might be OK if different records)');
      }

      // Compare ward field
      final wardWard = wardData['ward'];
      final stakWard = stakData['ward'];
      buf.writeln('\n     Ward Field:');
      buf.writeln('       Wards: "ward" = "$wardWard"');
      buf.writeln('       Stakeholders: "ward" = "$stakWard"');
    } catch (e) {
      buf.writeln('❌ Error analyzing field consistency: $e');
    }
    return buf.toString();
  }

  /// Test actual Firestore queries
  Future<String> _testQueries() async {
    final buf = StringBuffer();
    try {
      final user = _auth.currentUser;
      if (user == null) {
        buf.writeln('❌ No user logged in');
        return buf.toString();
      }

      // Get user state
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userState = userDoc['state'] as String?;

      if (userState == null) {
        buf.writeln('❌ User state is null');
        return buf.toString();
      }

      buf.writeln('Testing queries for state: "$userState"\n');

      // Test 1: Get LGAs
      buf.writeln('Query 1: Get LGAs for state "$userState"');
      final lgaQuery = await _firestore
          .collection('wards')
          .where('state', isEqualTo: userState)
          .get();
      buf.writeln('   Result: ${lgaQuery.docs.length} documents');

      if (lgaQuery.docs.isNotEmpty) {
        final lgas = <String>{};
        for (final doc in lgaQuery.docs) {
          final lga = doc['lga'];
          lgas.add(lga);
        }
        buf.writeln('   Unique LGAs: ${lgas.toList()}');

        // Test 2: Get wards for first LGA
        if (lgas.isNotEmpty) {
          final firstLga = lgas.first;
          buf.writeln('\nQuery 2: Get wards for state "$userState", lga "$firstLga"');
          final wardQuery = await _firestore
              .collection('wards')
              .where('state', isEqualTo: userState)
              .where('lga', isEqualTo: firstLga)
              .get();
          buf.writeln('   Result: ${wardQuery.docs.length} documents');

          if (wardQuery.docs.isNotEmpty) {
            final wards = <String>{};
            for (final doc in wardQuery.docs) {
              final ward = doc['ward'];
              wards.add(ward);
            }
            buf.writeln('   Wards: ${wards.toList()}');
          }
        }
      } else {
        buf.writeln('   ❌ CRITICAL: No documents returned!');
        buf.writeln('   This confirms the state mismatch issue.');
      }

      // Test 3: Get stakeholders
      buf.writeln('\nQuery 3: Get stakeholders for state "$userState"');
      final stakQuery = await _firestore
          .collection('stakeholders')
          .where('state', isEqualTo: userState)
          .limit(5)
          .get();
      buf.writeln('   Result: ${stakQuery.docs.length} documents (limited to 5)');

      if (stakQuery.docs.isNotEmpty) {
        buf.writeln('   Sample stakeholder fields:');
        final stakData = stakQuery.docs.first.data();
        for (final key in ['name', 'state', 'lg', 'ward']) {
          if (stakData.containsKey(key)) {
            buf.writeln('     - $key: "${stakData[key]}"');
          }
        }
      }
    } catch (e) {
      buf.writeln('❌ Error running queries: $e');
    }
    return buf.toString();
  }

  /// Print diagnostic report to console
  Future<void> printDiagnostic() async {
    final report = await runCompleteDiagnostic();
    debugPrint(report);
  }
}
