import 'package:flutter/material.dart';

import 'understanding_result_screen.dart';

class PatientQuizScreen extends StatefulWidget {
  final Map<String, dynamic> doctorAnalysis;

  const PatientQuizScreen({
    super.key,
    required this.doctorAnalysis,
  });

  @override
  State<PatientQuizScreen> createState() => _PatientQuizScreenState();
}

class _PatientQuizScreenState extends State<PatientQuizScreen> {
  late List<Map<String, dynamic>> _questions;

  int _current = 0;
  final Map<int, String> _answers = {};

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
  }

  List<Map<String, dynamic>> _buildQuestions() {
    final medicines = widget.doctorAnalysis['medicines'];

    final questions = <Map<String, dynamic>>[];

    if (medicines is List && medicines.isNotEmpty) {
      final medicine = medicines.first;

      final name = medicine['name']?.toString() ?? 'the medicine';
      final timing = medicine['timing'];

      String timingText = 'as instructed by the doctor';

      if (timing is List && timing.isNotEmpty) {
        timingText = timing.join(' and ');
      }

      questions.add({
        'question': 'When should you take $name?',
        'options': [
          timingText,
          'Only when you feel unwell',
        ],
        'correct': timingText,
      });

      final duration = medicine['duration']?.toString();

      if (duration != null &&
          duration.isNotEmpty &&
          duration != 'null') {
        questions.add({
          'question': 'How long did the doctor ask you to take it?',
          'options': [
            duration,
            'Only for one day',
          ],
          'correct': duration,
        });
      }
    }

    final precautions = widget.doctorAnalysis['precautions'];

    if (precautions is List && precautions.isNotEmpty) {
      final precaution = precautions.first.toString();

      questions.add({
        'question': 'Which instruction did the doctor give you?',
        'options': [
          precaution,
          'No precautions were given',
        ],
        'correct': precaution,
      });
    }

    if (questions.isEmpty) {
      questions.add({
        'question': 'What should you do with the doctor\'s instructions?',
        'options': [
          'Follow the instructions given by the healthcare professional',
          'Change the instructions yourself',
        ],
        'correct':
        'Follow the instructions given by the healthcare professional',
      });
    }

    return questions;
  }

  void _select(String answer) {
    setState(() {
      _answers[_current] = answer;
    });
  }

  void _next() {
    if (!_answers.containsKey(_current)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an answer.'),
        ),
      );
      return;
    }

    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
      });
      return;
    }

    _finish();
  }

  void _finish() {
    int correct = 0;

    for (int i = 0; i < _questions.length; i++) {
      if (_answers[i] == _questions[i]['correct']) {
        correct++;
      }
    }

    final summary =
        'Patient selected $correct out of ${_questions.length} answers that match the recorded instructions.';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => UnderstandingResultScreen(
          doctorAnalysis: widget.doctorAnalysis,
          patientResponse: summary,
          sourceType: 'quiz',
          quizScore: correct,
          totalQuestions: _questions.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_current];

    final options = List<String>.from(question['options']);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text('Understanding Check'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question ${_current + 1} of ${_questions.length}',
                style: const TextStyle(
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              Text(
                question['question'],
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 30),

              ...options.map(
                    (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _select(option),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _answers[_current] == option
                            ? const Color(0xFFEDE9FE)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _answers[_current] == option
                              ? const Color(0xFF7C3AED)
                              : Colors.black12,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    _current == _questions.length - 1
                        ? 'Finish Understanding Check'
                        : 'Next',
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