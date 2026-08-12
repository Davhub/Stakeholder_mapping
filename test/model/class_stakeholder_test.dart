import 'package:flutter_test/flutter_test.dart';
import 'package:impact_konnect/model/class_stakeholder.dart';

void main() {
  group('Stakeholder.fromFirestore field fallbacks', () {
    test('reads LGA from the canonical "LGA" field when present', () {
      final stakeholder = Stakeholder.fromFirestore({
        'name': 'Jane Doe',
        'LGA': 'Ibadan North',
        'ward': 'Ward 1',
        'state': 'Oyo',
        'country': 'Nigeria',
        'association': 'Health Workers',
        'phNumber': '08000000000',
        'whNumber': '08000000000',
      });

      expect(stakeholder.lg, 'Ibadan North');
    });

    test('falls back to "lg" then "lga" when "LGA" is absent', () {
      final fromLg = Stakeholder.fromFirestore({'lg': 'Egbeda'});
      final fromLga = Stakeholder.fromFirestore({'lga': 'Akinyele'});

      expect(fromLg.lg, 'Egbeda');
      expect(fromLga.lg, 'Akinyele');
    });

    test('falls back to "Ward" when "ward" is absent', () {
      final stakeholder = Stakeholder.fromFirestore({'Ward': 'Bodija'});
      expect(stakeholder.ward, 'Bodija');
    });

    test('falls back to "whatsappNumber" when "whNumber" is absent', () {
      final stakeholder =
          Stakeholder.fromFirestore({'whatsappNumber': '08011111111'});
      expect(stakeholder.whNumber, '08011111111');
    });

    test('falls back to "phoneNumber" when "phNumber" is absent', () {
      final stakeholder =
          Stakeholder.fromFirestore({'phoneNumber': '08022222222'});
      expect(stakeholder.phNumber, '08022222222');
    });

    test('defaults every field to empty string when the document is empty',
        () {
      final stakeholder = Stakeholder.fromFirestore(const {});

      expect(stakeholder.name, '');
      expect(stakeholder.lg, '');
      expect(stakeholder.ward, '');
      expect(stakeholder.phNumber, '');
      expect(stakeholder.whNumber, '');
    });
  });

  group('Stakeholder.toFirestore writes all known field-name variants', () {
    test('writes both LGA casing variants and both phone-field variants', () {
      final stakeholder = Stakeholder(
        name: 'Jane Doe',
        ward: 'Bodija',
        lg: 'Ibadan North',
        state: 'Oyo',
        country: 'Nigeria',
        association: 'Health Workers',
        phNumber: '08000000000',
        whNumber: '08011111111',
      );

      final data = stakeholder.toFirestore();

      expect(data['LGA'], 'Ibadan North');
      expect(data['lg'], 'Ibadan North');
      expect(data['lga'], 'Ibadan North');
      expect(data['ward'], 'Bodija');
      expect(data['Ward'], 'Bodija');
      expect(data['phNumber'], '08000000000');
      expect(data['phoneNumber'], '08000000000');
      expect(data['whNumber'], '08011111111');
      expect(data['whatsappNumber'], '08011111111');
    });

    test('round-trips through toFirestore -> fromFirestore unchanged', () {
      final original = Stakeholder(
        name: 'Jane Doe',
        ward: 'Bodija',
        lg: 'Ibadan North',
        state: 'Oyo',
        country: 'Nigeria',
        association: 'Health Workers',
        phNumber: '08000000000',
        whNumber: '08011111111',
      );

      final roundTripped = Stakeholder.fromFirestore(original.toFirestore());

      expect(roundTripped.name, original.name);
      expect(roundTripped.ward, original.ward);
      expect(roundTripped.lg, original.lg);
      expect(roundTripped.state, original.state);
      expect(roundTripped.phNumber, original.phNumber);
      expect(roundTripped.whNumber, original.whNumber);
    });
  });
}
