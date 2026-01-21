import 'package:flutter/material.dart';
import 'package:mapping/web_admin/services/admin_firestore_service.dart';
import 'package:mapping/web_admin/models/dashboard_models.dart';
import 'package:mapping/model/model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WebStakeholdersTable extends StatefulWidget {
  const WebStakeholdersTable({Key? key}) : super(key: key);

  @override
  State<WebStakeholdersTable> createState() => _WebStakeholdersTableState();
}

class _WebStakeholdersTableState extends State<WebStakeholdersTable> {
  final AdminFirestoreService _service = AdminFirestoreService();
  String? _adminState;

  TableFilterState _filterState = TableFilterState(
    sortBy: 'createdAt',
    ascending: false,
  );

  PaginationState _paginationState = PaginationState.initial();
  DocumentSnapshot? _lastDocument;
  List<Map<String, dynamic>> _currentStakeholders =
      []; // Store both doc ID and stakeholder
  bool _isLoading = false;

  List<String> _lgas = [];
  List<String> _wards = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _adminState = await _service.getAdminState();
    if (_adminState != null) {
      await _loadDropdownData();
      await _loadStakeholders();
    }
  }

  Future<void> _loadDropdownData() async {
    final lgas = await _service.getUniqueLGAs(_adminState!);
    final wards = await _service.getUniqueWards(_adminState!);

    setState(() {
      _lgas = lgas;
      _wards = wards;
    });
  }

  Future<void> _loadStakeholders() async {
    if (_adminState == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await _service
          .getStakeholdersStream(
            adminState: _adminState!,
            limit: _paginationState.itemsPerPage,
            startAfter: _lastDocument,
            lgaFilter: _filterState.lgaFilter,
            wardFilter: _filterState.wardFilter,
          )
          .first;

      final stakeholders = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'stakeholder': Stakeholder.fromFirestore(doc),
        };
      }).toList();

      setState(() {
        _currentStakeholders = stakeholders;
        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.last;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stakeholders: $e')),
        );
      }
    }
  }

  void _applySearch(String query) {
    setState(() {
      _filterState = _filterState.copyWith(searchQuery: query);
    });
    _performSearch();
  }

  Future<void> _performSearch() async {
    if (_adminState == null || _filterState.searchQuery.isEmpty) {
      await _loadStakeholders();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _service.searchStakeholders(
        adminState: _adminState!,
        searchQuery: _filterState.searchQuery,
      );

      // Note: Search doesn't include doc IDs, we'd need to modify service for that
      setState(() {
        _currentStakeholders = results.map((stakeholder) {
          return {
            'id': '', // Empty ID for search results
            'stakeholder': stakeholder,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddStakeholderDialog() {
    _showStakeholderDialog(null, null);
  }

  void _showEditStakeholderDialog(String docId, Stakeholder stakeholder) {
    _showStakeholderDialog(docId, stakeholder);
  }

  void _showStakeholderDialog(String? docId, Stakeholder? stakeholder) {
    final isEditing = stakeholder != null && docId != null;
    final formKey = GlobalKey<FormState>();

    final nameController =
        TextEditingController(text: stakeholder?.fullName ?? '');
    final phoneController =
        TextEditingController(text: stakeholder?.phoneNumber ?? '');
    final whatsappController =
        TextEditingController(text: stakeholder?.whatsappNumber ?? '');
    final emailController =
        TextEditingController(text: stakeholder?.email ?? '');
    final associationController =
        TextEditingController(text: stakeholder?.association ?? '');
    final countryController =
        TextEditingController(text: stakeholder?.country ?? 'Nigeria');

    String? selectedLga = stakeholder?.lg;
    String? selectedWard = stakeholder?.ward;
    String? selectedLevel = stakeholder?.levelOfAdministration;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                isEditing ? Icons.edit_rounded : Icons.add_rounded,
                color: Colors.deepPurple,
              ),
              const SizedBox(width: 12),
              Text(isEditing ? 'Edit Stakeholder' : 'Add Stakeholder'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: whatsappController,
                      decoration: InputDecoration(
                        labelText: 'WhatsApp Number *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter WhatsApp number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.email_rounded),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: countryController,
                      decoration: InputDecoration(
                        labelText: 'Country *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.flag_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter country';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: associationController,
                      decoration: InputDecoration(
                        labelText: 'Association *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.groups_rounded),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter association';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedLga,
                      decoration: InputDecoration(
                        labelText: 'Local Government Area *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.location_city_rounded),
                      ),
                      items: _lgas.map((lga) {
                        return DropdownMenuItem(value: lga, child: Text(lga));
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedLga = value;
                          selectedWard = null; // Reset ward when LGA changes
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select LGA';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedWard,
                      decoration: InputDecoration(
                        labelText: 'Ward *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.place_rounded),
                      ),
                      items: _wards.map((ward) {
                        return DropdownMenuItem(value: ward, child: Text(ward));
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedWard = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select ward';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedLevel,
                      decoration: InputDecoration(
                        labelText: 'Level of Administration *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon:
                            const Icon(Icons.admin_panel_settings_rounded),
                      ),
                      items: ['State', 'LGA', 'Ward'].map((level) {
                        return DropdownMenuItem(
                            value: level, child: Text(level));
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedLevel = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select level';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final stakeholderData = {
                    'fullName': nameController.text.trim(),
                    'phoneNumber': phoneController.text.trim(),
                    'whatsappNumber': whatsappController.text.trim(),
                    'email': emailController.text.trim(),
                    'country': countryController.text.trim(),
                    'association': associationController.text.trim(),
                    'state': _adminState!,
                    'lg': selectedLga!,
                    'ward': selectedWard!,
                    'levelOfAdministration': selectedLevel!,
                  };

                  try {
                    if (isEditing) {
                      await _service.updateStakeholder(
                        docId,
                        stakeholderData,
                      );
                    } else {
                      await _service.createStakeholder(stakeholderData);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEditing
                                ? 'Stakeholder updated successfully'
                                : 'Stakeholder added successfully',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                      await _loadStakeholders();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String docId, Stakeholder stakeholder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Confirmation'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${stakeholder.fullName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _service.deleteStakeholder(docId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stakeholder deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  await _loadStakeholders();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_adminState == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Filter Bar
          _buildSearchAndFilters(),
          const SizedBox(height: 24),

          // Data Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDataTable(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, phone, or association...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _applySearch,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterState.lgaFilter,
              decoration: InputDecoration(
                labelText: 'Filter by LGA',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All LGAs')),
                ..._lgas.map(
                    (lga) => DropdownMenuItem(value: lga, child: Text(lga))),
              ],
              onChanged: (value) {
                setState(() {
                  _filterState = _filterState.copyWith(
                    lgaFilter: value,
                    wardFilter: null,
                  );
                });
                _loadStakeholders();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filterState.wardFilter,
              decoration: InputDecoration(
                labelText: 'Filter by Ward',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Wards')),
                ..._wards.map(
                    (ward) => DropdownMenuItem(value: ward, child: Text(ward))),
              ],
              onChanged: (value) {
                setState(() {
                  _filterState = _filterState.copyWith(wardFilter: value);
                });
                _loadStakeholders();
              },
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _showAddStakeholderDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Stakeholder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    if (_currentStakeholders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No stakeholders found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 24,
        headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
        columns: const [
          DataColumn(
              label:
                  Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label:
                  Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('Association',
                  style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label:
                  Text('LGA', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label:
                  Text('Ward', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label:
                  Text('Level', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('Actions',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _currentStakeholders.map((item) {
          final docId = item['id'] as String;
          final stakeholder = item['stakeholder'] as Stakeholder;

          return DataRow(cells: [
            DataCell(Text(stakeholder.fullName)),
            DataCell(Text(stakeholder.phoneNumber)),
            DataCell(Text(stakeholder.association)),
            DataCell(Text(stakeholder.lg)),
            DataCell(Text(stakeholder.ward)),
            DataCell(Text(stakeholder.levelOfAdministration)),
            DataCell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded, size: 20),
                    color: Colors.blue,
                    onPressed: docId.isNotEmpty
                        ? () => _showEditStakeholderDialog(docId, stakeholder)
                        : null,
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_rounded, size: 20),
                    color: Colors.red,
                    onPressed: docId.isNotEmpty
                        ? () => _showDeleteConfirmation(docId, stakeholder)
                        : null,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }
}
