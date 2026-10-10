import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import 'auth_screen.dart';

/// Temporary landing page so login has somewhere to go.
/// Next step: replace with the real Patient Profile / Home.
class HomePlaceholder extends StatelessWidget {
  final SmritiUser user;
  const HomePlaceholder({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmritiColors.blush,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
              const SizedBox(height: 28),
              Text('Hello, ${user.name} 👋',
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: SmritiColors.plum)),
              const SizedBox(height: 6),
              Text(
                'Language: ${user.language}'
                    '${user.age != null ? '  •  Age: ${user.age}' : ''}',
                style: const TextStyle(color: SmritiColors.ink),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  '✓ Login works.\n\nNext screen to build: Patient Profile → '
                      'Doctor Instruction Capture → Voice Teach-Back.',
                  style: TextStyle(
                      height: 1.5, fontSize: 15, color: SmritiColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}