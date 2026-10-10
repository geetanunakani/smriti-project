import 'package:flutter/material.dart';

class DoctorAnalysisScreen extends StatefulWidget {
  final String audioPath;

  const DoctorAnalysisScreen({
    super.key,
    required this.audioPath,
  });

  @override
  State<DoctorAnalysisScreen> createState() =>
      _DoctorAnalysisScreenState();
}

class _DoctorAnalysisScreenState
    extends State<DoctorAnalysisScreen> {

  @override
  void initState() {
    super.initState();

    _analyze();
  }

  Future<void> _analyze() async {
    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    // For now this is the analysis result screen.
    // Next we connect the recorded audio to the AI API.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Understanding the doctor',
          style: TextStyle(
            color: Color(0xFF57113A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 50),

            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFE0EC),
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 55,
                color: Color(0xFFC02E69),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Analyzing the doctor’s voice',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color(0xFF57113A),
              ),
            ),

            const SizedBox(height: 15),

            const Text(
              'SMRITI is converting the consultation into clear instructions.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF765968),
              ),
            ),

            const SizedBox(height: 40),

            const LinearProgressIndicator(
              color: Color(0xFFC02E69),
              backgroundColor: Color(0xFFFFE0EC),
            ),

            const SizedBox(height: 30),

            _step(
              Icons.graphic_eq,
              'Listening to the recording',
            ),

            _step(
              Icons.text_fields,
              'Understanding the doctor’s words',
            ),

            _step(
              Icons.list_alt,
              'Extracting important instructions',
            ),

            _step(
              Icons.verified,
              'Preparing your consultation summary',
            ),

            const Spacer(),

            Text(
              'Recorded file:\n${widget.audioPath}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _step(
      IconData icon,
      String text,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          const SizedBox(width: 5),

          Icon(
            icon,
            color: const Color(0xFFC02E69),
          ),

          const SizedBox(width: 15),

          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF57113A),
            ),
          ),
        ],
      ),
    );
  }
}