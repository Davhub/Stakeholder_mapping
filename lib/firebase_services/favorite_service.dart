import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:risdi/model/favorite_model.dart';
import 'package:risdi/model/stakeholder_contact_model.dart';

class FavoriteService {
  static final FavoriteService _instance = FavoriteService._internal();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  factory FavoriteService() {
    return _instance;
  }

  FavoriteService._internal();

  /// Get current user ID from Firebase Auth
  String? _getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Generate a unique ID for stakeholder (using fullName as identifier)
  String _generateStakeholderId(Stakeholder stakeholder) {
    return stakeholder.fullName.toLowerCase().replaceAll(' ', '_');
  }

  /// Add a stakeholder to favorites
  /// Returns true if successful, false if already favorited or error occurred
  Future<bool> addFavorite(Stakeholder stakeholder) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        print('Error: User not authenticated');
        return false;
      }

      final stakeholderId = _generateStakeholderId(stakeholder);

      // Check if already favorited
      final existingFav = await _db
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('stakeholderId', isEqualTo: stakeholderId)
          .get();

      if (existingFav.docs.isNotEmpty) {
        print('Stakeholder already favorited');
        return false;
      }

      // Add to favorites
      final favorite = Favorite(
        id: '', // Firestore will generate
        userId: userId,
        stakeholderId: stakeholderId,
        stakeholderName: stakeholder.fullName,
        stakeholderAssociation: stakeholder.association,
        stakeholderLG: stakeholder.lg,
        stakeholderWard: stakeholder.ward,
        stakeholderState: stakeholder.state,
        addedAt: DateTime.now(),
      );

      await _db.collection('favorites').add(favorite.toFirestore());
      print('Favorite added successfully');
      return true;
    } catch (e) {
      print('Error adding favorite: $e');
      return false;
    }
  }

  /// Remove a stakeholder from favorites
  /// Returns true if successful, false if not found or error occurred
  Future<bool> removeFavorite(Stakeholder stakeholder) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        print('Error: User not authenticated');
        return false;
      }

      final stakeholderId = _generateStakeholderId(stakeholder);

      // Find and delete the favorite
      final querySnapshot = await _db
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('stakeholderId', isEqualTo: stakeholderId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('Favorite not found');
        return false;
      }

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      print('Favorite removed successfully');
      return true;
    } catch (e) {
      print('Error removing favorite: $e');
      return false;
    }
  }

  /// Check if a stakeholder is favorited
  /// Returns true if favorited, false otherwise
  Future<bool> isFavorite(Stakeholder stakeholder) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        return false;
      }

      final stakeholderId = _generateStakeholderId(stakeholder);

      final querySnapshot = await _db
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('stakeholderId', isEqualTo: stakeholderId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  /// Toggle favorite status for a stakeholder
  /// Returns true if now favorited, false if now unfavorited
  Future<bool?> toggleFavorite(Stakeholder stakeholder) async {
    try {
      final isFav = await isFavorite(stakeholder);

      if (isFav) {
        final success = await removeFavorite(stakeholder);
        return success ? false : null; // Return false if unfavorited
      } else {
        final success = await addFavorite(stakeholder);
        return success ? true : null; // Return true if favorited
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      return null;
    }
  }

  /// Get all favorites for current user
  /// Returns a list of Favorite objects, sorted by most recent first
  Future<List<Favorite>> getFavorites() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        print('Error: User not authenticated');
        return [];
      }

      final querySnapshot = await _db
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .orderBy('addedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Favorite.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  /// Get a stream of favorites for real-time updates
  Stream<List<Favorite>> getFavoritesStream() {
    final userId = _getCurrentUserId();
    if (userId == null) {
      return Stream.value([]);
    }

    return _db
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Favorite.fromFirestore(doc)).toList());
  }

  /// Get count of favorites for current user
  Future<int> getFavoritesCount() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        return 0;
      }

      final querySnapshot = await _db
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }

  /// Search favorites by stakeholder name
  Future<List<Favorite>> searchFavorites(String searchQuery) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        return [];
      }

      final querySnapshot = await _db
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('stakeholderName', isGreaterThanOrEqualTo: searchQuery)
          .where('stakeholderName',
              isLessThan: searchQuery + 'z') // Simple prefix search
          .orderBy('stakeholderName')
          .get();

      return querySnapshot.docs
          .map((doc) => Favorite.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error searching favorites: $e');
      return [];
    }
  }

  /// Batch check multiple stakeholders for favorite status
  /// Returns a map of stakeholderIds to their favorite status
  Future<Map<String, bool>> checkMultipleFavorites(
      List<Stakeholder> stakeholders) async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        return {};
      }

      final stakeholderIds =
          stakeholders.map((s) => _generateStakeholderId(s)).toList();

      final querySnapshot = await _db
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .where('stakeholderId', whereIn: stakeholderIds)
          .get();

      final favoritedIds = querySnapshot.docs
          .map((doc) => doc['stakeholderId'] as String)
          .toSet();

      return {for (var id in stakeholderIds) id: favoritedIds.contains(id)};
    } catch (e) {
      print('Error batch checking favorites: $e');
      return {};
    }
  }

  /// Clear all favorites for current user (use with caution)
  Future<bool> clearAllFavorites() async {
    try {
      final userId = _getCurrentUserId();
      if (userId == null) {
        print('Error: User not authenticated');
        return false;
      }

      final querySnapshot = await _db
          .collection('favorites')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      print('All favorites cleared');
      return true;
    } catch (e) {
      print('Error clearing favorites: $e');
      return false;
    }
  }
}
