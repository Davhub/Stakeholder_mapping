import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:risdi/services/location_service.dart';
import 'package:risdi/core/utils/location_utils.dart';

class AddStakeholderScreen extends StatefulWidget {
  final String adminId; // The logged-in admin's ID

  AddStakeholderScreen({required this.adminId});

  @override
  _AddStakeholderScreenState createState() => _AddStakeholderScreenState();
}

class _AddStakeholderScreenState extends State<AddStakeholderScreen> {
  final _formKey = GlobalKey<FormState>();
  late LocationService _locationService;
  late Future<String?> _adminStateFuture;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _associationController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _whatsappNumberController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _levelOfAdministrationController =
      TextEditingController();

  // Dropdown values
  String? _selectedLGA;
  String? _selectedWard;

  // Dynamic location data from Firestore
  List<String> _availableLGAs = [];
  List<String> _availableWards = [];
  bool _isLoadingLGAs = false;
  bool _isLoadingWards = false;
  String? _lgaLoadError;
  String? _wardLoadError;

  /// Initialize LocationService for dynamic location data
  Future<void> _initializeLocationService() async {
    _locationService = LocationService();
    try {
      await _locationService.initialize();
      debugPrint('LocationService initialized in AddStakeholderScreen');
    } catch (e) {
      debugPrint('Error initializing LocationService: $e');
    }
  }

  /// Load LGAs for a specific state
  Future<void> _loadLGAsForState(String state) async {
    if (state.isEmpty) return;
    
    setState(() {
      _isLoadingLGAs = true;
      _lgaLoadError = null;
    });

    try {
      final lgas = await _locationService.getLGAsForState(state);
      if (mounted) {
        setState(() {
          _availableLGAs = lgas;
          _isLoadingLGAs = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading LGAs: $e');
      if (mounted) {
        setState(() {
          _lgaLoadError = 'Failed to load LGAs';
          _isLoadingLGAs = false;
        });
      }
    }
  }

  /// Load wards for a specific LGA
  Future<void> _loadWardsForLGA(String state, String lga) async {
    if (state.isEmpty || lga.isEmpty) return;
    
    setState(() {
      _isLoadingWards = true;
      _wardLoadError = null;
    });

    try {
      final wards = await _locationService.getWardsForLGA(state, lga);
      if (mounted) {
        setState(() {
          _availableWards = wards;
          _isLoadingWards = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading wards: $e');
      if (mounted) {
        setState(() {
          _wardLoadError = 'Failed to load wards';
          _isLoadingWards = false;
        });
      }
    }
  }

  /// Fetch the admin's state from Firestore
  Future<String?> _fetchAdminState() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.adminId)
          .get();
      
      if (doc.exists) {
        final state = doc.data()?['state'] as String?;
        // Normalize state for consistent matching with Firestore wards collection
        if (state != null && state.isNotEmpty) {
          return LocationUtils.normalizeDisplay(state);
        }
        return state;
      }
    } catch (e) {
      debugPrint('Error fetching admin state: $e');
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initializeLocationService();
    if (widget.adminId.isEmpty) {
      print('Error: adminId is empty');
    } else {
      print('Admin ID: ${widget.adminId}');
    }
    _countryController.text = 'Nigeria'; // Default country
    _adminStateFuture = _fetchAdminState();
  }

  void _addStakeholder() async {
    if (_formKey.currentState!.validate()) {
      try {
        final normalizedLga = _selectedLGA != null
            ? LocationUtils.normalizeDisplay(_selectedLGA!)
            : '';
        final normalizedWard = _selectedWard != null
            ? LocationUtils.normalizeDisplay(_selectedWard!)
            : '';
        final normalizedState = LocationUtils.normalizeDisplay(_stateController.text);

        await FirebaseFirestore.instance.collection('stakeholders').add({
          'fullName': _nameController.text,
          // Persist both variants to maintain compatibility across consumers
          'LGA': normalizedLga,
          'lg': normalizedLga,
          'association': _associationController.text,
          'country': _countryController.text,
          'state': normalizedState,
          'ward': normalizedWard,
          'Ward': normalizedWard,
          'phoneNumber': _phoneNumberController.text,
          'whatsappNumber': _whatsappNumberController.text,
          'email': _emailController.text,
          'levelOfAdministration': _levelOfAdministrationController.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stakeholder added successfully!')),
        );

        Navigator.of(context).pop();
      } catch (e) {
        print('Error adding stakeholder: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error adding stakeholder. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Stakeholder'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<String?>(
        future: _adminStateFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            print('FutureBuilder error: ${snapshot.error}');
            return const Center(
              child: Text('Error loading admin data.'),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('State data unavailable. Please check your role.'),
            );
          }

          final adminState = snapshot.data!;
          _stateController.text = adminState;
          
          // Load LGAs for the admin's state using post-frame callback to avoid state conflicts during build
          if (adminState.isNotEmpty && _availableLGAs.isEmpty && !_isLoadingLGAs) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_availableLGAs.isEmpty && !_isLoadingLGAs) {
                _loadLGAsForState(adminState);
              }
            });
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Personal Information Section
                _buildSectionHeader('Personal Information'),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_nameController, 'Full Name'),
                        const SizedBox(height: 16),
                        _buildTextField(_phoneNumberController, 'Phone Number'),
                        const SizedBox(height: 16),
                        _buildTextField(
                            _whatsappNumberController, 'WhatsApp Number'),
                        const SizedBox(height: 16),
                        _buildTextField(_emailController, 'Email'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Location Information Section
                _buildSectionHeader('Location Information'),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_countryController, 'Country',
                            readOnly: true),
                        const SizedBox(height: 16),
                        _buildTextField(_stateController, 'State',
                            readOnly: true),
                        const SizedBox(height: 16),
                        // LGA dropdown with loading/error states
                        if (_isLoadingLGAs)
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (_lgaLoadError != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _lgaLoadError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        else if (_availableLGAs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'No LGAs available for your state',
                              style: TextStyle(color: Colors.orange),
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: _selectedLGA,
                            isExpanded: true,
                            items: _availableLGAs.map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLGA = value;
                                _selectedWard = null;
                              });
                              if (value != null && value.isNotEmpty && _stateController.text.isNotEmpty) {
                                _loadWardsForLGA(_stateController.text, value);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'LGA',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please select LGA.';
                              return null;
                            },
                          ),
                        const SizedBox(height: 16),
                        // Ward dropdown with loading/error states
                        if (_isLoadingWards)
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (_wardLoadError != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _wardLoadError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        else if (_availableWards.isEmpty && _selectedLGA != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'No wards found for LGA: ${_selectedLGA ?? ""}',
                              style: const TextStyle(color: Colors.orange),
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: _selectedWard,
                            isExpanded: true,
                            items: _availableWards.map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedWard = value;
                              });
                            },
                            decoration: InputDecoration(
                              labelText: 'Ward',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please select Ward.';
                              return null;
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Additional Information Section
                _buildSectionHeader('Additional Information'),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildTextField(_levelOfAdministrationController,
                            'Level of Administration'),
                        const SizedBox(height: 16),
                        _buildTextField(_associationController, 'Association'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _addStakeholder,
                  child: const Text(
                    'Add Stakeholder',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label.';
        }
        return null;
      },
    );
  }

  
}
