import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risdi/screens/onboarding_screen.dart';

void main() {
  testWidgets('Onboarding screen uses a scrollable layout for large text scaling', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
          child: OnboardingScreen(),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsWidgets);
  });
}
