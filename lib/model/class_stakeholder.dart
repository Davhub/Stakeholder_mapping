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
    return Stakeholder(
      name: data['name'],
      ward: data['ward'],
      lg: data['lg'],
      state: data['state'],
      country: data['country'],
      association: data['association'],
      phNumber: data['phNumber'],
      whNumber: data['whNumber'],
    );
  }

  // Convert a Stakeholder object to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ward': ward,
      'lg': lg,
      'state': state,
      'country': country,
      'association': association,
      'phNumber': phNumber,
      'whatsappNumber': whNumber,
    };
  }
}
