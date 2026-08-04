import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:risdi/main.dart';

void main() {
  testWidgets('MyApp builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
