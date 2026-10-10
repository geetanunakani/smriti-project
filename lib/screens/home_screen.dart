import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import 'auth_screen.dart';
import 'consent_screen.dart';
import 'report_screen.dart';
import 'reminders_screen.dart';
import 'patient_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final SmritiUser user;
  const HomeScreen({super.key, required this.user});

  void _soon(BuildContext context, String name) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$name - coming soon')));
  }

  void _openFeature(BuildContext context, String name) {
    if (name == 'Report Analysis') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReportScreen(user: user),
        ),
      );
    } else if (name == 'Reminders') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RemindersScreen(user: user),
        ),
      );
    } else if (name == 'Patient Profile') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PatientProfileScreen(user: user),
        ),
      );
    } else {
      _soon(context, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    const features = <_Feature>[
      _Feature('Report Analysis', 'Scan, simplify, compare',
          Icons.document_scanner_rounded),
      _Feature('Guardians', 'Share with family', Icons.shield_rounded),
      _Feature('Patient Profile', 'Visits, medicines, reports',
          Icons.person_rounded),
      _Feature('Reminders', 'From confirmed prescriptions', Icons.alarm_rounded),
      _Feature('Diet Rules', "Doctor's food instructions",
          Icons.restaurant_rounded),
    ];

    return Scaffold(
      backgroundColor: SmritiColors.blush,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('SMRITI',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: SmritiColors.plum)),
                  IconButton(
                    tooltip: 'Log out',
                    icon: const Icon(Icons.logout_rounded,
                        color: SmritiColors.rose),
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text('Hello, ${user.name} 👋',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: SmritiColors.plum)),
              const SizedBox(height: 4),
              const Text('From what is heard - to what is remembered.',
                  style: TextStyle(color: SmritiColors.ink)),
              const SizedBox(height: 22),

              // ---------- CORE FEATURE ----------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SmritiColors.plum, SmritiColors.rose],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CORE',
                        style: TextStyle(
                            color: SmritiColors.roseLight,
                            fontSize: 11,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('Understanding Verification',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text(
                      'Record your consultation with consent, then explain '
                          'it back in your own words. SMRITI checks if the '
                          "doctor's message landed.",
                      style: TextStyle(
                          color: SmritiColors.petal, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: SmritiColors.plum,
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => ConsentScreen(user: user)),
                      ),
                      icon: const Icon(Icons.mic_rounded),
                      label: const Text('Start consultation'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),
              const Text('Care tools',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: SmritiColors.plum)),
              const SizedBox(height: 12),

              // ---------- SUPPORTING FEATURES ----------
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [
                  for (final f in features)
                    _FeatureTile(
                      feature: f,
                      onTap: () => _openFeature(context, f.title),
                    ),
                ],
              ),

              const SizedBox(height: 22),
              const Center(
                child: Text('SMRITI verifies understanding - not medicine.',
                    style: TextStyle(color: SmritiColors.mauve, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Feature(this.title, this.subtitle, this.icon);
}

class _FeatureTile extends StatelessWidget {
  final _Feature feature;
  final VoidCallback onTap;
  const _FeatureTile({required this.feature, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: SmritiColors.petal,
                  shape: BoxShape.circle,
                ),
                child: Icon(feature.icon, color: SmritiColors.rose),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(feature.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: SmritiColors.plum)),
                  const SizedBox(height: 2),
                  Text(feature.subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: SmritiColors.ink)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
