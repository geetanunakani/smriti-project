import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import 'recording_screen.dart';

class ConsentScreen extends StatefulWidget {
  final SmritiUser user;

  const ConsentScreen({
    super.key,
    required this.user,
  });

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _agreed = false;

  void _continue() {
    if (!_agreed) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecordingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmritiColors.blush,
      appBar: AppBar(
        backgroundColor: SmritiColors.blush,
        elevation: 0,
        foregroundColor: SmritiColors.plum,
        title: const Text(
          'Before we start',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your consent comes first',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: SmritiColors.plum,
                      ),
                    ),
                    SizedBox(height: 14),

                    _Point(
                      Icons.mic_rounded,
                      'SMRITI will record your consultation using the phone microphone.',
                    ),

                    _Point(
                      Icons.edit_note_rounded,
                      "The recording is turned into a list of the doctor's instructions.",
                    ),

                    _Point(
                      Icons.record_voice_over_rounded,
                      'Afterwards you explain it back in your own words.',
                    ),

                    _Point(
                      Icons.verified_user_rounded,
                      'SMRITI never diagnoses, prescribes or corrects the doctor. A mismatch is only shown so you can re-confirm with a human.',
                    ),

                    _Point(
                      Icons.privacy_tip_rounded,
                      'Please tell your doctor that the consultation is being recorded.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              CheckboxListTile(
                value: _agreed,
                onChanged: (value) {
                  setState(() {
                    _agreed = value ?? false;
                  });
                },
                activeColor: SmritiColors.rose,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'I consent to recording this consultation.',
                  style: TextStyle(
                    color: SmritiColors.plum,
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: SmritiColors.rose,
                  ),
                  onPressed: _agreed ? _continue : null,
                  icon: const Icon(Icons.mic_rounded),
                  label: const Text(
                    'Continue to recording',
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

class _Point extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Point(
      this.icon,
      this.text,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: SmritiColors.rose,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                height: 1.4,
                color: SmritiColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}