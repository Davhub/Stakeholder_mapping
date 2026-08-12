import 'package:flutter_test/flutter_test.dart';
import 'package:impact_konnect/main.dart';

void main() {
  test('kWebAdminRoles grants access to web-dashboard roles only, never '
      'the mobile field-admin role or the default mobile-signup role', () {
    expect(kWebAdminRoles, containsAll(['Super Admin', 'Analyst']));
    expect(kWebAdminRoles, isNot(contains('Admin')));
    expect(kWebAdminRoles, isNot(contains('User')));
  });
}
