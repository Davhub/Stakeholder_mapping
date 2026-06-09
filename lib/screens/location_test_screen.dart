import 'package:flutter/material.dart';
import 'package:risdi/services/location_test_service.dart';

/// Test screen to run LocationService tests
/// Add this route to test LocationService functionality
class LocationTestScreen extends StatelessWidget {
  const LocationTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Service Tests'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LocationService Test Suite',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'This screen tests if the app can communicate with Firestore and retrieve LGA/Ward data from the wards collection.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Run the test suite
                runAllTests();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tests running... Check console output')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Run All Tests',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tests will run:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('• Direct Firestore access to wards collection'),
            const Text('• LocationService initialization and state retrieval'),
            const Text('• LGA retrieval for a state'),
            const Text('• Ward retrieval for LGA'),
            const Text('• Stakeholder queries with fixed LGA field'),
            const SizedBox(height: 30),
            const Text(
              'Check the debug console for detailed test results.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}