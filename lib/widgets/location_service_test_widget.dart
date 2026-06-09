import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:risdi/services/location_service.dart';

/// Test widget to verify LocationService can communicate with Firestore
/// and retrieve LGA/Ward data from the wards collection
class LocationServiceTestWidget extends StatefulWidget {
  const LocationServiceTestWidget({super.key});

  @override
  State<LocationServiceTestWidget> createState() => _LocationServiceTestWidgetState();
}

class _LocationServiceTestWidgetState extends State<LocationServiceTestWidget> {
  final LocationService _locationService = LocationService();
  bool _isInitialized = false;
  bool _isLoading = false;
  String _status = 'Not initialized';
  List<String> _states = [];
  List<String> _lgas = [];
  List<String> _wards = [];
  String _selectedState = '';
  String _selectedLGA = '';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
      _status = 'Initializing LocationService...';
    });

    try {
      await _locationService.initialize();
      _states = _locationService.getAllStates();

      setState(() {
        _isInitialized = true;
        _isLoading = false;
        _status = '✅ LocationService initialized successfully. Found ${_states.length} states: ${_states.join(", ")}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = '❌ Error initializing LocationService: $e';
      });
    }
  }

  Future<void> _testLGAQuery(String state) async {
    setState(() {
      _isLoading = true;
      _status = 'Testing LGA query for state: $state...';
      _selectedState = state;
      _lgas = [];
      _wards = [];
    });

    try {
      final lgas = await _locationService.getLGAsForState(state);
      setState(() {
        _lgas = lgas;
        _isLoading = false;
        _status = '✅ LGA query successful. Found ${lgas.length} LGAs for $state: ${lgas.join(", ")}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = '❌ Error querying LGAs for $state: $e';
      });
    }
  }

  Future<void> _testWardQuery(String state, String lga) async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Ward query for $state -> $lga...';
      _selectedLGA = lga;
      _wards = [];
    });

    try {
      final wards = await _locationService.getWardsForLGA(state, lga);
      setState(() {
        _wards = wards;
        _isLoading = false;
        _status = '✅ Ward query successful. Found ${wards.length} wards for $state/$lga: ${wards.join(", ")}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = '❌ Error querying wards for $state/$lga: $e';
      });
    }
  }

  Future<void> _testDirectFirestoreQuery() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing direct Firestore query to wards collection...';
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection('wards').get();

      setState(() {
        _isLoading = false;
        _status = '✅ Direct Firestore query successful. Found ${snapshot.docs.length} documents in wards collection.';
      });

      // Log first few documents for debugging
      for (int i = 0; i < min(3, snapshot.docs.length); i++) {
        final doc = snapshot.docs[i];
        final data = doc.data();
        debugPrint('Document $i: ${doc.id} -> state: ${data['state']}, lga: ${data['lga']}, ward: ${data['ward']}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = '❌ Error with direct Firestore query: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LocationService Test'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _status.contains('✅') ? Colors.green.shade100 :
                       _status.contains('❌') ? Colors.red.shade100 : Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            // Test Buttons
            ElevatedButton(
              onPressed: _isLoading ? null : _testDirectFirestoreQuery,
              child: const Text('Test Direct Firestore Query'),
            ),

            const SizedBox(height: 10),

            if (_states.isNotEmpty) ...[
              const Text('States:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: _states.map((state) => ElevatedButton(
                  onPressed: _isLoading ? null : () => _testLGAQuery(state),
                  child: Text(state),
                )).toList(),
              ),

              const SizedBox(height: 20),
            ],

            if (_lgas.isNotEmpty) ...[
              Text('LGAs for $_selectedState:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: _lgas.map((lga) => ElevatedButton(
                  onPressed: _isLoading ? null : () => _testWardQuery(_selectedState, lga),
                  child: Text(lga),
                )).toList(),
              ),

              const SizedBox(height: 20),
            ],

            if (_wards.isNotEmpty) ...[
              Text('Wards for $_selectedState/$_selectedLGA:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8,
                children: _wards.map((ward) => Chip(
                  label: Text(ward),
                )).toList(),
              ),
            ],

            const Spacer(),

            // Instructions
            const Text(
              'Instructions:\n'
              '1. Click "Test Direct Firestore Query" to verify wards collection access\n'
              '2. Click a state to test LGA retrieval\n'
              '3. Click an LGA to test ward retrieval\n'
              '4. Check debug console for detailed logs',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

int min(int a, int b) => a < b ? a : b;