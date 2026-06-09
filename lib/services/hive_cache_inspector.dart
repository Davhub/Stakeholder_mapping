import 'package:hive/hive.dart';
import 'package:risdi/model/stakeholder_contact_model.dart';

/// Inspect Hive cache to see what LGA/Ward data is stored
void inspectHiveCache() async {
  print('🔍 Inspecting Hive Cache for old hardcoded data...\n');

  try {
    // Open the stakeholders box
    final stakeholdersBox = await Hive.openBox<Stakeholder>('stakeholders');

    print('📦 Stakeholders Cache:');
    print('  Total cached stakeholders: ${stakeholdersBox.length}');

    if (stakeholdersBox.isNotEmpty) {
      // Get all stakeholders
      final stakeholders = stakeholdersBox.values.toList();

      // Extract unique LGAs and Wards
      final lgas = stakeholders.map((s) => s.lg).where((lg) => lg.isNotEmpty).toSet();
      final wards = stakeholders.map((s) => s.ward).where((ward) => ward.isNotEmpty).toSet();

      print('  Unique LGAs in cache: ${lgas.length} - ${lgas.join(", ")}');
      print('  Unique Wards in cache: ${wards.length}');

      // Show sample stakeholders
      print('\n📋 Sample cached stakeholders (first 5):');
      for (int i = 0; i < stakeholders.length && i < 5; i++) {
        final s = stakeholders[i];
        print('  ${i+1}. ${s.fullName} - LGA: "${s.lg}", Ward: "${s.ward}"');
      }

      // Check if these match known hardcoded lists
      final knownHardcodedLGAs = {'Agege', 'Ikorodu', 'Shomolu', 'Victoria Island'};
      final cachedLGAs = lgas.toSet();
      final intersection = knownHardcodedLGAs.intersection(cachedLGAs);

      if (intersection.isNotEmpty) {
        print('\n⚠️  FOUND HARDCODED DATA IN CACHE!');
        print('  Cache contains these known hardcoded LGAs: ${intersection.join(", ")}');
        print('  This explains why user sees hardcoded lists despite no source code containing them.');
      } else {
        print('\n✅ No hardcoded data found in cache.');
      }

    } else {
      print('  Cache is empty');
    }

    await stakeholdersBox.close();

  } catch (e) {
    print('❌ Error inspecting cache: $e');
  }
}

/// Clear the Hive cache
void clearHiveCache() async {
  print('🧹 Clearing Hive Cache...\n');

  try {
    final stakeholdersBox = await Hive.openBox<Stakeholder>('stakeholders');
    await stakeholdersBox.clear();
    await stakeholdersBox.close();

    print('✅ Hive cache cleared successfully');
    print('  Next app restart will fetch fresh data from Firestore');

  } catch (e) {
    print('❌ Error clearing cache: $e');
  }
}