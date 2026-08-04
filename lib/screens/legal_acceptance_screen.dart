import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:risdi/component/auth_form.dart';
import 'package:risdi/core/constants/legal_content.dart';
import 'package:risdi/screens/legal_document_screen.dart';

/// Shown once on first launch, after onboarding, before the user can reach
/// the sign-in screen. The user must explicitly agree to both the Privacy
/// Policy and Terms & Conditions to proceed; declining either keeps them on
/// this screen indefinitely.
class LegalAcceptanceScreen extends StatefulWidget {
  const LegalAcceptanceScreen({super.key});

  @override
  State<LegalAcceptanceScreen> createState() => _LegalAcceptanceScreenState();
}

class _LegalAcceptanceScreenState extends State<LegalAcceptanceScreen> {
  bool _acceptedPrivacyPolicy = false;
  bool _acceptedTerms = false;

  bool get _canContinue => _acceptedPrivacyPolicy && _acceptedTerms;

  Future<void> _accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acceptedLegalTerms', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  void _openDocument(String title, String body) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LegalDocumentScreen(title: title, body: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.gavel_outlined, size: 56, color: Colors.blue),
              const SizedBox(height: 16),
              const Text(
                'Before you continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Please review and accept our Privacy Policy and Terms & '
                'Conditions to continue using RISDi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 32),
              CheckboxListTile(
                value: _acceptedPrivacyPolicy,
                onChanged: (value) {
                  setState(() => _acceptedPrivacyPolicy = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    const Expanded(
                      child: Text('I have read and agree to the'),
                    ),
                    TextButton(
                      onPressed: () => _openDocument(
                        kPrivacyPolicyTitle,
                        kPrivacyPolicyText,
                      ),
                      child: const Text('Privacy Policy'),
                    ),
                  ],
                ),
              ),
              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (value) {
                  setState(() => _acceptedTerms = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Row(
                  children: [
                    const Expanded(
                      child: Text('I have read and agree to the'),
                    ),
                    TextButton(
                      onPressed: () => _openDocument(
                        kTermsAndConditionsTitle,
                        kTermsAndConditionsText,
                      ),
                      child: const Text('Terms & Conditions'),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _canContinue ? _accept : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Accept & Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You cannot use RISDi without accepting both documents.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
