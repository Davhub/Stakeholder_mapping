import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impact_konnect/screens/admin_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Admin dashboard keeps content scrollable on small screens with larger text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(360, 640),
          textScaler: TextScaler.linear(1.4),
        ),
        child: const MaterialApp(
          home: AdminDashboardScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Filter Stakeholders'), findsOneWidget);
    expect(find.text('Total Stakeholders'), findsOneWidget);
  });
}
