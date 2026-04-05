import 'package:cloud_firestore/cloud_firestore.dart';

class Favorite {
  final String id; // Firestore document ID
  final String userId;
  final String
      stakeholderId; // Reference to stakeholder by fullName or unique identifier
  final String stakeholderName;
  final String stakeholderAssociation;
  final String stakeholderLG;
  final String stakeholderWard;
  final String stakeholderState;
  final DateTime addedAt;

  Favorite({
    required this.id,
    required this.userId,
    required this.stakeholderId,
    required this.stakeholderName,
    required this.stakeholderAssociation,
    required this.stakeholderLG,
    required this.stakeholderWard,
    required this.stakeholderState,
    required this.addedAt,
  });

  // Factory constructor to create a Favorite object from Firestore
  factory Favorite.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Favorite(
      id: doc.id,
      userId: data['userId'] ?? '',
      stakeholderId: data['stakeholderId'] ?? '',
      stakeholderName: data['stakeholderName'] ?? '',
      stakeholderAssociation: data['stakeholderAssociation'] ?? '',
      stakeholderLG: data['stakeholderLG'] ?? '',
      stakeholderWard: data['stakeholderWard'] ?? '',
      stakeholderState: data['stakeholderState'] ?? '',
      addedAt: (data['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert a Favorite object to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'stakeholderId': stakeholderId,
      'stakeholderName': stakeholderName,
      'stakeholderAssociation': stakeholderAssociation,
      'stakeholderLG': stakeholderLG,
      'stakeholderWard': stakeholderWard,
      'stakeholderState': stakeholderState,
      'addedAt': addedAt,
    };
  }

  // Create a copy with modified fields
  Favorite copyWith({
    String? id,
    String? userId,
    String? stakeholderId,
    String? stakeholderName,
    String? stakeholderAssociation,
    String? stakeholderLG,
    String? stakeholderWard,
    String? stakeholderState,
    DateTime? addedAt,
  }) {
    return Favorite(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      stakeholderId: stakeholderId ?? this.stakeholderId,
      stakeholderName: stakeholderName ?? this.stakeholderName,
      stakeholderAssociation:
          stakeholderAssociation ?? this.stakeholderAssociation,
      stakeholderLG: stakeholderLG ?? this.stakeholderLG,
      stakeholderWard: stakeholderWard ?? this.stakeholderWard,
      stakeholderState: stakeholderState ?? this.stakeholderState,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Favorite &&
        other.id == id &&
        other.stakeholderId == stakeholderId &&
        other.userId == userId;
  }

  @override
  int get hashCode => id.hashCode ^ stakeholderId.hashCode ^ userId.hashCode;
}
