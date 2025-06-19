import 'package:flutter/material.dart';
import 'package:mapping/screens/screen.dart';

class AdminStakeholderViewScreen extends StatefulWidget {
  final Map<String, dynamic> stakeholder;
  final String stakeholderId;
  final Map<String, dynamic> stakeholderData;

  const AdminStakeholderViewScreen(
      {Key? key,
      required this.stakeholder,
      required this.stakeholderId,
      required this.stakeholderData})
      : super(key: key);

  @override
  State<AdminStakeholderViewScreen> createState() =>
      _AdminStakeholderViewScreenState();
}

class _AdminStakeholderViewScreenState
    extends State<AdminStakeholderViewScreen> {
  //capitalization functions
  void _editStakeholder(
      String stakeholderId, Map<String, dynamic> stakeholderData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditStakeholderScreen(
            stakeholderId: stakeholderId,
            stakeholderData: stakeholderData,
            data: {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffe9f7fc),
      appBar: AppBar(
        title: Text(widget.stakeholder['name'] ?? 'Stakeholder Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', widget.stakeholder['fullName'].toString()),
            _buildDetailRow('Ward', widget.stakeholder['ward'].toString()),
            _buildDetailRow('LGA', widget.stakeholder['lg'].toString()),
            _buildDetailRow('State', widget.stakeholder['state'].toString()),
            _buildDetailRow(
                'Country', widget.stakeholder['country'].toString()),
            _buildDetailRow(
                'Phone Number', widget.stakeholder['phoneNumber'].toString()),
            _buildDetailRow('Whatsapp Number',
                widget.stakeholder['whatsappNumber'].toString()),
            _buildDetailRow(
                'Email Address', widget.stakeholder['email'].toString()),
            _buildDetailRow('Level of Administration',
                widget.stakeholder['levelOfAdministration'].toString()),
            _buildDetailRow(
                'Association', widget.stakeholder['association'].toString()),
            const SizedBox(height: 16),

            //edit and delete button
          ],
        ),
      ),
    );
  }

  // Helper method to create detail rows
  Widget _buildDetailRow(String label, String? value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Expanded(
                child: Text(
                  value ?? 'NaN',
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),
        const Divider()
      ],
    );
  }
}
