import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditStakeholderScreen extends StatefulWidget {
  final String stakeholderId;
  final Map<String, dynamic> stakeholderData;

  EditStakeholderScreen(
      {required this.stakeholderId,
      required this.stakeholderData,
      required Map<String, dynamic> data});

  @override
  _EditStakeholderScreenState createState() => _EditStakeholderScreenState();
}

class _EditStakeholderScreenState extends State<EditStakeholderScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _lgController;
  late TextEditingController _associationController;
  late TextEditingController _stateController;
  late TextEditingController _wardController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController = TextEditingController(
        text: widget.stakeholderData['fullName'].toString());
    _lgController =
        TextEditingController(text: widget.stakeholderData['lg'].toString());
    _associationController = TextEditingController(
        text: widget.stakeholderData['association'].toString());
    _stateController =
        TextEditingController(text: widget.stakeholderData['state'].toString());
    _wardController =
        TextEditingController(text: widget.stakeholderData['ward'].toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lgController.dispose();
    _associationController.dispose();
    _stateController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  void _updateStakeholder() async {
    if (_formKey.currentState!.validate()) {
      // Update stakeholder data in Firestore
      await FirebaseFirestore.instance
          .collection('stakeholders')
          .doc(widget.stakeholderId)
          .update({
        'fullName': _nameController.text,
        'lg': _lgController.text,
        'association': _associationController.text,
        'state': _stateController.text,
        'ward': _wardController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stakeholder updated successfully!')),
      );
      Navigator.of(context).pop(); // Return to previous screen after update
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Stakeholder')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _lgController,
                decoration:
                    const InputDecoration(labelText: 'Local Government Area'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an LGA' : null,
              ),
              TextFormField(
                controller: _associationController,
                decoration: const InputDecoration(labelText: 'Association'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an association' : null,
              ),
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'State'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a state' : null,
              ),
              TextFormField(
                controller: _wardController,
                decoration: const InputDecoration(labelText: 'Ward'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a ward' : null,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _updateStakeholder,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.all(
                      Radius.circular(15),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Center(
                      child: Text(
                        'Update Stakeholder',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
