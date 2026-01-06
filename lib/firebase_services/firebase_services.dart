import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapping/model/model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch stakeholders based on filters
  Future<List<Stakeholder>> fetchFilteredHolders(
      String? country, String? state, String? lg, String? ward) async {
    Query query = _db.collection('stakeholders');

    if (country != null && country.isNotEmpty) {
      query = query.where('country', isEqualTo: country);
    }
    if (state != null && state.isNotEmpty) {
      query = query.where('state', isEqualTo: state);
    }
    if (lg != null && lg.isNotEmpty) {
      query = query.where('lg', isEqualTo: lg);
    }
    if (ward != null && ward.isNotEmpty) {
      query = query.where('ward', isEqualTo: ward);
    }

    try {
      QuerySnapshot querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => Stakeholder.fromFirestore(doc))
          .toList();
    } catch (e) {
      // Handle any errors that occur during the query
      print('Error fetching filtered holders: $e');
      return [];
    }
  }
}
