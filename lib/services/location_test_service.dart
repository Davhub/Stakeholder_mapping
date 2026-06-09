import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:risdi/services/location_service.dart';

/// Simple test to verify LocationService can communicate with Firestore
/// Run this to test if wards collection queries work
void testLocationService() async {
  print('🧪 Starting LocationService Test...');

  final locationService = LocationService();

  try {
    print('1️⃣ Initializing LocationService...');
    await locationService.initialize();
    print('✅ LocationService initialized successfully');

    // Test 1: Get all states
    print('\n2️⃣ Testing getAllStates()...');
    final states = locationService.getAllStates();
    print('✅ Found ${states.length} states: $states');

    if (states.isNotEmpty) {
      final testState = states.first;
      print('\n3️⃣ Testing getLGAsForState("$testState")...');

      final lgas = await locationService.getLGAsForState(testState);
      print('✅ Found ${lgas.length} LGAs for $testState: $lgas');

      if (lgas.isNotEmpty) {
        final testLGA = lgas.first;
        print('\n4️⃣ Testing getWardsForLGA("$testState", "$testLGA")...');

        final wards = await locationService.getWardsForLGA(testState, testLGA);
        print('✅ Found ${wards.length} wards for $testState/$testLGA: $wards');
      }
    }

    print('\n🎉 ALL TESTS PASSED! LocationService can communicate with Firestore.');

  } catch (e) {
    print('❌ TEST FAILED: $e');
  }
}

/// Test direct Firestore access to wards collection
void testDirectFirestoreAccess() async {
  print('🔥 Testing Direct Firestore Access to wards collection...');

  try {
    final snapshot = await FirebaseFirestore.instance.collection('wards').get();

    print('✅ Successfully queried wards collection');
    print('📊 Found ${snapshot.docs.length} documents');

    // Show sample documents
    print('\n📋 Sample documents:');
    for (int i = 0; i < snapshot.docs.length && i < 5; i++) {
      final doc = snapshot.docs[i];
      final data = doc.data();
      print('  Doc ${i+1}: ${doc.id} -> state: ${data['state']}, lga: ${data['lga']}, ward: ${data['ward']}');
    }

    // Count unique states, LGAs
    final states = snapshot.docs.map((d) => d.data()['state']).toSet();
    final lgas = snapshot.docs.map((d) => d.data()['lga']).toSet();

    print('\n📈 Summary:');
    print('  States: ${states.length} (${states.join(", ")})');
    print('  LGAs: ${lgas.length}');

  } catch (e) {
    print('❌ Direct Firestore test failed: $e');
  }
}

/// Test stakeholder queries (the ones we fixed)
void testStakeholderQueries() async {
  print('👥 Testing Stakeholder Queries (with fixed LGA field)...');

  try {
    // Test query that was previously failing
    final snapshot = await FirebaseFirestore.instance
        .collection('stakeholders')
        .where('state', isEqualTo: 'Lagos')
        .where('LGA', isEqualTo: 'Agege')  // This was 'lg' before our fix
        .limit(5)
        .get();

    print('✅ Stakeholder query successful');
    print('📊 Found ${snapshot.docs.length} stakeholders in Lagos/Agege');

    if (snapshot.docs.isNotEmpty) {
      print('\n📋 Sample stakeholders:');
      for (int i = 0; i < snapshot.docs.length && i < 3; i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        print('  ${data['fullName']} - ${data['LGA']}/${data['ward']}');
      }
    }

  } catch (e) {
    print('❌ Stakeholder query test failed: $e');
  }
}

/// Run all tests
void runAllTests() {
  print('🚀 Running Complete Location & Stakeholder Test Suite\n');

  testDirectFirestoreAccess();
  print('\n' + '='*50 + '\n');

  testLocationService();
  print('\n' + '='*50 + '\n');

  testStakeholderQueries();
  print('\n' + '='*50 + '\n');

  print('🏁 Test Suite Complete');
}