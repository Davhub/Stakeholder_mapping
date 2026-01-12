import 'package:flutter/material.dart';
import 'package:mapping/model/model.dart';
import 'package:mapping/component/recent_stakeholders_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class StakeholderView extends StatefulWidget {
  const StakeholderView({super.key, required this.holder});

  final Stakeholder holder;

  @override
  State<StakeholderView> createState() => _StakeholderViewState();
}

class _StakeholderViewState extends State<StakeholderView> {
  @override
  void initState() {
    super.initState();
    // Add this stakeholder to recent views when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RecentStakeholdersManager.addToRecentStakeholders(widget.holder);
    });
  }

  // Function to launch the phone dialer
  void _launchDialer(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      throw 'Could not launch $phoneNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Stakeholder Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Gradient
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.white.withOpacity(0.9), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(60),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.holder.fullName.isNotEmpty
                              ? widget.holder.fullName[0].toUpperCase()
                              : 'S',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.holder.fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.holder.association,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Contact Information Card
                  _buildSectionCard(
                    title: 'Contact Information',
                    icon: Icons.contact_phone,
                    children: [
                      _buildDetailTile(
                        icon: Icons.phone,
                        label: 'Phone Number',
                        value: widget.holder.phoneNumber,
                        onTap: () => _launchDialer(widget.holder.phoneNumber),
                        isClickable: true,
                      ),
                      _buildDetailTile(
                        icon: Icons.chat,
                        label: 'WhatsApp',
                        value: widget.holder.whatsappNumber,
                      ),
                      _buildDetailTile(
                        icon: Icons.email,
                        label: 'Email',
                        value: widget.holder.email,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location Information Card
                  _buildSectionCard(
                    title: 'Location Information',
                    icon: Icons.location_on,
                    children: [
                      _buildDetailTile(
                        icon: Icons.map,
                        label: 'State',
                        value: widget.holder.state,
                      ),
                      _buildDetailTile(
                        icon: Icons.location_city,
                        label: 'Local Government',
                        value: widget.holder.lg,
                      ),
                      _buildDetailTile(
                        icon: Icons.place,
                        label: 'Ward',
                        value: widget.holder.ward,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Administrative Information Card
                  _buildSectionCard(
                    title: 'Administrative Information',
                    icon: Icons.admin_panel_settings,
                    children: [
                      _buildDetailTile(
                        icon: Icons.business,
                        label: 'Association',
                        value: widget.holder.association,
                      ),
                      _buildDetailTile(
                        icon: Icons.layers,
                        label: 'Level of Administration',
                        value: widget.holder.levelOfAdministration,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    bool isClickable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isClickable ? Colors.blue : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (isClickable)
                Icon(Icons.phone, color: Colors.blue, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
