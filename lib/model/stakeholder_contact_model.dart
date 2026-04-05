import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'stakeholder_contact_model.g.dart'; // This is needed for the generated code

@HiveType(typeId: 0)
class Stakeholder extends HiveObject {
  @HiveField(0)
  final String fullName;

  @HiveField(1)
  final String phoneNumber;

  @HiveField(2)
  final String whatsappNumber;

  @HiveField(3)
  final String email;
  @HiveField(4)
  final String association;

  @HiveField(5)
  final String levelOfAdministration;

  @HiveField(6)
  final String country;

  @HiveField(7)
  final String state;

  @HiveField(8)
  final String lg;

  @HiveField(9)
  final String ward;

  Stakeholder({
    required this.fullName,
    required this.phoneNumber,
    required this.whatsappNumber,
    required this.email,
    required this.association,
    required this.levelOfAdministration,
    required this.country,
    required this.state,
    required this.lg,
    required this.ward,
  });

  // Factory constructor to create a Stakeholder object from Firestore
  factory Stakeholder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Stakeholder(
      fullName: _sanitizeField(data['fullName']),
      phoneNumber: _sanitizeField(data['phoneNumber']),
      whatsappNumber: _sanitizeField(data['whatsappNumber']),
      email: _sanitizeField(data['email']),
      association: _sanitizeField(data['association']),
      levelOfAdministration: _sanitizeField(data['levelOfAdministration']),
      country: _sanitizeField(data['country']),
      state: _sanitizeField(data['state']),
      lg: _sanitizeField(data['lg']),
      ward: _sanitizeField(data['ward']),
    );
  }

  static String _sanitizeField(dynamic value) {
    if (value == null) {
      return ''; // Return an empty string if the field is null
    }

    if (value is double && value.isNaN) {
      return ''; // Handle NaN values by returning an empty string
    }

    return value.toString(); // Convert any other value to a string
  }
}
