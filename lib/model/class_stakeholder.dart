class Stakeholder {
  final String name;
  final String ward;
  final String lg;
  final String state;
  final String country;
  final String association;
  final String phNumber;
  final String whNumber;

  Stakeholder({
    required this.name,
    required this.ward,
    required this.lg,
    required this.state,
    required this.country,
    required this.association,
    required this.phNumber,
    required this.whNumber,
  });

  // Convert a Firestore document to a Stakeholder object
  factory Stakeholder.fromFirestore(Map<String, dynamic> data) {
    final lgaValue = data['LGA'] ?? data['lg'] ?? data['lga'] ?? '';
    final whNumberValue = data['whNumber'] ?? data['whatsappNumber'] ?? '';

    return Stakeholder(
      name: data['name'] ?? '',
      ward: data['ward'] ?? data['Ward'] ?? '',
      lg: lgaValue.toString(),
      state: data['state'] ?? '',
      country: data['country'] ?? '',
      association: data['association'] ?? '',
      phNumber: data['phNumber'] ?? data['phoneNumber'] ?? '',
      whNumber: whNumberValue.toString(),
    );
  }

  // Convert a Stakeholder object to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ward': ward,
      'Ward': ward,
      'LGA': lg,
      'lg': lg,
      'lga': lg,
      'state': state,
      'country': country,
      'association': association,
      'phNumber': phNumber,
      'phoneNumber': phNumber,
      'whNumber': whNumber,
      'whatsappNumber': whNumber,
    };
  }
}
