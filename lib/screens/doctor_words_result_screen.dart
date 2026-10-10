import 'package:flutter/material.dart';


import 'patient_method_screen.dart';

class DoctorWordsResultScreen extends StatelessWidget {
  final Map<String, dynamic> doctorAnalysis;

  const DoctorWordsResultScreen({
    super.key,
    required this.doctorAnalysis,
  });

  List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    final doctorName = doctorAnalysis['doctorName']?.toString();
    final healthIssue = doctorAnalysis['healthIssue']?.toString();

    final medicines = doctorAnalysis['medicines'] is List
        ? List<Map<String, dynamic>>.from(
      (doctorAnalysis['medicines'] as List).map(
            (e) => Map<String, dynamic>.from(e as Map),
      ),
    )
        : <Map<String, dynamic>>[];

    final tests = _stringList(doctorAnalysis['tests']);
    final precautions = _stringList(doctorAnalysis['precautions']);
    final foodRestrictions =
    _stringList(doctorAnalysis['foodRestrictions']);
    final warningSigns = _stringList(doctorAnalysis['warningSigns']);
    final otherInstructions =
    _stringList(doctorAnalysis['otherInstructions']);

    final followUp = doctorAnalysis['followUp']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text(
          'Doctor\'s Instructions',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6C63FF),
                      Color(0xFF8E7CFF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 30,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'What the doctor said',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'SMRITI has organized the instructions from your consultation.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (doctorName != null &&
                  doctorName.isNotEmpty &&
                  doctorName != 'null')
                _infoCard(
                  icon: Icons.medical_services_outlined,
                  title: 'Healthcare Professional',
                  child: Text(
                    doctorName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              if (healthIssue != null &&
                  healthIssue.isNotEmpty &&
                  healthIssue != 'null')
                _infoCard(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Health Issue Mentioned',
                  child: Text(
                    healthIssue,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),

              // MEDICINES
              if (medicines.isNotEmpty)
                _infoCard(
                  icon: Icons.medication_outlined,
                  title: 'Medicines',
                  child: Column(
                    children: medicines.map((medicine) {
                      final name = medicine['name']?.toString() ?? '';
                      final dose = medicine['dose']?.toString();
                      final frequency =
                      medicine['frequency']?.toString();

                      final timing = _stringList(medicine['timing']);

                      final duration =
                      medicine['duration']?.toString();

                      final notes =
                      medicine['notes']?.toString();

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F2FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            if (dose != null &&
                                dose != 'null' &&
                                dose.isNotEmpty)
                              _detailRow('Dose', dose),

                            if (frequency != null &&
                                frequency != 'null' &&
                                frequency.isNotEmpty)
                              _detailRow(
                                'Frequency',
                                frequency,
                              ),

                            if (timing.isNotEmpty)
                              _detailRow(
                                'Timing',
                                timing.join(', '),
                              ),

                            if (duration != null &&
                                duration != 'null' &&
                                duration.isNotEmpty)
                              _detailRow(
                                'Duration',
                                duration,
                              ),

                            if (notes != null &&
                                notes != 'null' &&
                                notes.isNotEmpty)
                              _detailRow(
                                'Notes',
                                notes,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              if (tests.isNotEmpty)
                _listCard(
                  icon: Icons.science_outlined,
                  title: 'Tests Mentioned',
                  items: tests,
                ),

              if (precautions.isNotEmpty)
                _listCard(
                  icon: Icons.warning_amber_rounded,
                  title: 'Precautions',
                  items: precautions,
                ),

              if (foodRestrictions.isNotEmpty)
                _listCard(
                  icon: Icons.restaurant_outlined,
                  title: 'Food Restrictions',
                  items: foodRestrictions,
                ),

              if (warningSigns.isNotEmpty)
                _listCard(
                  icon: Icons.notification_important_outlined,
                  title: 'Warning Signs Mentioned',
                  items: warningSigns,
                ),

              if (otherInstructions.isNotEmpty)
                _listCard(
                  icon: Icons.notes_outlined,
                  title: 'Other Instructions',
                  items: otherInstructions,
                ),

              if (followUp != null &&
                  followUp.isNotEmpty &&
                  followUp != 'null')
                _infoCard(
                  icon: Icons.calendar_month_outlined,
                  title: 'Follow-up',
                  child: Text(
                    followUp,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),

              const SizedBox(height: 10),

              // IMPORTANT SMRITI MESSAGE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5E1FF),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.record_voice_over_outlined,
                      color: Color(0xFF6C63FF),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Now let\'s check what you understood from the consultation.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // CONTINUE BUTTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientMethodScreen(
                          doctorAnalysis: doctorAnalysis,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.psychology_outlined),
                      SizedBox(width: 10),
                      Text(
                        'Check My Understanding',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              const Center(
                child: Text(
                  'SMRITI does not diagnose or change medical instructions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF6C63FF),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _listCard({
    required IconData icon,
    required String title,
    required List<String> items,
  }) {
    return _infoCard(
      icon: icon,
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '•  ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 13,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}