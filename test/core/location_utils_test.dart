import 'package:flutter_test/flutter_test.dart';
import 'package:impact_konnect/core/utils/location_utils.dart';

void main() {
  group('LocationUtils.normalizeDisplay', () {
    test('title-cases each word', () {
      expect(LocationUtils.normalizeDisplay('ibadan north'), 'Ibadan North');
      expect(LocationUtils.normalizeDisplay('IBADAN NORTH'), 'Ibadan North');
    });

    test('trims leading/trailing whitespace and collapses internal spaces',
        () {
      expect(LocationUtils.normalizeDisplay('  Ogun   State  '),
          'Ogun State');
    });

    test('returns empty string for empty or whitespace-only input', () {
      expect(LocationUtils.normalizeDisplay(''), '');
      expect(LocationUtils.normalizeDisplay('   '), '');
    });
  });

  group('LocationUtils.equalsIgnoreCase', () {
    test('treats different casing and surrounding whitespace as equal', () {
      expect(LocationUtils.equalsIgnoreCase('Ogun', 'ogun'), isTrue);
      expect(LocationUtils.equalsIgnoreCase(' Ogun ', 'Ogun'), isTrue);
      expect(LocationUtils.equalsIgnoreCase('Ogun State', 'Ogun'), isFalse);
    });
  });

  group('LocationUtils.readStringField', () {
    test('returns the value of the first matching key in priority order',
        () {
      final data = {'lga': 'Akinyele', 'LGA': 'Ibadan North'};
      expect(LocationUtils.readStringField(data, ['LGA', 'lg', 'lga']),
          'Ibadan North');
    });

    test('falls through to a later key when earlier keys are absent', () {
      final data = {'lga': 'Akinyele'};
      expect(
          LocationUtils.readStringField(data, ['LGA', 'lg', 'lga']),
          'Akinyele');
    });

    test('returns null when none of the keys are present', () {
      expect(LocationUtils.readStringField(const {}, ['LGA', 'lg', 'lga']),
          isNull);
    });

    test('stringifies non-string values', () {
      final data = {'count': 5};
      expect(LocationUtils.readStringField(data, ['count']), '5');
    });
  });
}
