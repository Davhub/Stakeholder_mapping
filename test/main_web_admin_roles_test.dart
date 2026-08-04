import 'package:flutter_test/flutter_test.dart';
import 'package:risdi/main.dart';

void main() {
  test('kWebAdminRoles only grants access to elevated roles, never the '
      'default mobile-signup role', () {
    expect(kWebAdminRoles, containsAll(['Admin', 'Super Admin', 'Analyst']));
    expect(kWebAdminRoles, isNot(contains('User')));
  });
}
