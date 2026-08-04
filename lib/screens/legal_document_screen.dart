import 'package:flutter/material.dart';

/// Read-only viewer for a legal document (Privacy Policy or Terms &
/// Conditions). Used both from Profile > Quick Actions and from the
/// first-launch acceptance flow.
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String body;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Text(
            body,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
      ),
    );
  }
}
