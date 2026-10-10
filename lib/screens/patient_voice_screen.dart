import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../models/visit_record.dart';
import '../services/gemini_service.dart';
import 'understanding_result_screen.dart';

class PatientVoiceScreen extends StatefulWidget {
  final Map<String, dynamic> doctorAnalysis;

  const PatientVoiceScreen({
    super.key,
    required this.doctorAnalysis,
  });

  @override
  State<PatientVoiceScreen> createState() => _PatientVoiceScreenState();
}

class _PatientVoiceScreenState extends State<PatientVoiceScreen> {
  final AudioRecorder _recorder = AudioRecorder();

  bool _recording = false;
  bool _processing = false;

  String? _path;
  int _seconds = 0;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();

    if (!hasPermission) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required.'),
        ),
      );
      return;
    }

    final directory = await getTemporaryDirectory();

    final path =
        '${directory.path}/patient_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    setState(() {
      _recording = true;
      _seconds = 0;
      _path = path;
    });

    _startTimer();
  }

  void _startTimer() async {
    while (_recording && mounted) {
      await Future.delayed(const Duration(seconds: 1));

      if (!_recording || !mounted) return;

      setState(() {
        _seconds++;
      });
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();

    setState(() {
      _recording = false;
      _path = path ?? _path;
    });
  }

  Future<void> _analyze() async {
    if (_path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please record your answer first.'),
        ),
      );
      return;
    }

    setState(() {
      _processing = true;
    });

    try {
      // ============================================================
      // STEP 1: Convert patient's voice into text
      // ============================================================

      final transcriptResult =
      await GeminiService.instance.extractFromAudio(
        File(_path!),
        languageHint: 'Auto-detect',
      );

      final patientTranscript =
          transcriptResult['transcript']?.toString().trim() ?? '';

      if (patientTranscript.isEmpty) {
        throw Exception(
          'Could not understand the recording. Please try again.',
        );
      }

      // ============================================================
      // STEP 2: Create a VisitRecord from the doctor's instructions
      // ============================================================

      final visit = VisitRecord.fromAi(
        widget.doctorAnalysis,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        number: 1,
        date: DateTime.now(),
        language: 'English',
        audioPath: null,
      );

      // ============================================================
      // STEP 3: Compare patient's understanding with doctor
      // ============================================================

      final teachBackResult =
      await GeminiService.instance.compareTeachBack(
        visit,
        patientTranscript,
        visit.language,
      );

      if (!mounted) return;

      // ============================================================
      // STEP 4: Show semantic comparison result
      // ============================================================

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => UnderstandingResultScreen(
            doctorAnalysis: widget.doctorAnalysis,
            patientResponse: patientTranscript,
            sourceType: 'voice',
            teachBackResult: teachBackResult,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not analyze your understanding: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
    }
  }

  String _time() {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text('Voice Teach-Back'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const SizedBox(height: 30),

              const Icon(
                Icons.record_voice_over_rounded,
                size: 70,
                color: Color(0xFF7C3AED),
              ),

              const SizedBox(height: 22),

              const Text(
                'Tell us what you understood',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Explain the doctor\'s instructions in your own words.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 50),

              Text(
                _time(),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 25),

              GestureDetector(
                onTap: _recording
                    ? _stopRecording
                    : (_processing ? null : _startRecording),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _recording
                        ? Colors.red
                        : const Color(0xFF7C3AED),
                  ),
                  child: Icon(
                    _recording
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                _recording
                    ? 'Tap to stop'
                    : 'Tap to start recording',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),

              const Spacer(),

              if (_path != null && !_recording)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _processing ? null : _analyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _processing
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Analyze My Understanding',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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