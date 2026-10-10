import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../services/gemini_service.dart';
import 'doctor_words_result_screen.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isProcessing = false;

  String? _recordingPath;
  String _status = 'Ready to record your consultation.';

  Map<String, dynamic>? _analysis;

  Duration _recordingDuration = Duration.zero;
  DateTime? _recordingStartedAt;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartedAt;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // START RECORDING
  // ------------------------------------------------------------

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();

      if (!hasPermission) {
        _showMessage(
          'Microphone permission is required to record the consultation.',
        );
        return;
      }

      final directory = await getTemporaryDirectory();

      final fileName =
          'smriti_consultation_${DateTime.now().millisecondsSinceEpoch}.m4a';

      final path = '${directory.path}/$fileName';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _isProcessing = false;
        _recordingPath = path;
        _analysis = null;
        _status = 'Recording consultation...';
        _recordingStartedAt = DateTime.now();
        _pausedDuration = Duration.zero;
        _pauseStartedAt = null;
      });

      _updateDuration();
    } catch (e) {
      _showMessage('Could not start recording.\n$e');
    }
  }

  // ------------------------------------------------------------
  // UPDATE RECORDING TIMER
  // ------------------------------------------------------------

  void _updateDuration() {
    if (!_isRecording || _recordingStartedAt == null) {
      return;
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted || !_isRecording) {
        return;
      }

      if (!_isPaused) {
        final now = DateTime.now();

        final elapsed =
            now.difference(_recordingStartedAt!) - _pausedDuration;

        setState(() {
          _recordingDuration = elapsed;
        });
      }

      _updateDuration();
    });
  }

  // ------------------------------------------------------------
  // PAUSE
  // ------------------------------------------------------------

  Future<void> _pauseRecording() async {
    try {
      await _recorder.pause();

      setState(() {
        _isPaused = true;
        _pauseStartedAt = DateTime.now();
        _status = 'Recording paused.';
      });
    } catch (e) {
      _showMessage('Could not pause recording.\n$e');
    }
  }

  // ------------------------------------------------------------
  // RESUME
  // ------------------------------------------------------------

  Future<void> _resumeRecording() async {
    try {
      await _recorder.resume();

      if (_pauseStartedAt != null) {
        _pausedDuration +=
            DateTime.now().difference(_pauseStartedAt!);
      }

      setState(() {
        _isPaused = false;
        _pauseStartedAt = null;
        _status = 'Recording consultation...';
      });
    } catch (e) {
      _showMessage('Could not resume recording.\n$e');
    }
  }

  // ------------------------------------------------------------
  // STOP RECORDING
  // ------------------------------------------------------------

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();

      if (path == null || path.isEmpty) {
        _showMessage('Recording file was not created.');
        return;
      }

      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingPath = path;
        _status = 'Recording completed. Analyzing consultation...';
        _isProcessing = true;
      });

      await _analyzeRecording(path);
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _isProcessing = false;
        _status = 'Recording stopped.';
      });

      _showMessage('Could not stop recording.\n$e');
    }
  }

  // ------------------------------------------------------------
  // ANALYZE AUDIO WITH GEMINI SERVICE
  // ------------------------------------------------------------

  Future<void> _analyzeRecording(String path) async {
    try {
      final file = File(path);

      if (!await file.exists()) {
        throw Exception('Recording file could not be found.');
      }

      final result =
      await GeminiService.instance.extractFromAudio(file);

      if (!mounted) {
        return;
      }

      setState(() {
        _analysis = result;
        _isProcessing = false;
        _status = 'Consultation analyzed successfully.';
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorWordsResultScreen(
            doctorAnalysis: result,
          ),
        ),
      );
    } on AiException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
        _status = 'Analysis failed.';
      });

      _showMessage(e.message);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
        _status = 'Analysis failed.';
      });

      _showMessage(
        'Something went wrong while analyzing the consultation.\n$e',
      );
    }
  }

  // ------------------------------------------------------------
  // FORMAT TIME
  // ------------------------------------------------------------

  String _formatDuration(Duration duration) {
    final minutes =
    duration.inMinutes.remainder(60).toString().padLeft(2, '0');

    final seconds =
    duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text(
          'SMRITI Consultation',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF252238),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(),

              const SizedBox(height: 20),

              _buildRecordingCard(),

              const SizedBox(height: 20),

              if (_isProcessing)
                _buildProcessingCard(),

              if (_analysis != null)
                _buildAnalysisSection(),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER CARD
  // ------------------------------------------------------------

  Widget _buildHeaderCard() {
    return Container(
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
            Icons.record_voice_over_rounded,
            color: Colors.white,
            size: 38,
          ),
          SizedBox(height: 14),
          Text(
            'Capture what was said.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'SMRITI listens to the consultation and organizes the healthcare professional’s instructions for better understanding and follow-through.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // RECORDING CARD
  // ------------------------------------------------------------

  Widget _buildRecordingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE8E5F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 105,
            height: 105,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording
                  ? const Color(0xFFFFE7EC)
                  : const Color(0xFFF0EEFF),
            ),
            child: Icon(
              _isRecording
                  ? Icons.mic_rounded
                  : Icons.mic_none_rounded,
              size: 48,
              color: _isRecording
                  ? const Color(0xFFE54865)
                  : const Color(0xFF6C63FF),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            _isRecording
                ? (_isPaused ? 'Recording Paused' : 'Recording...')
                : 'Consultation Recording',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF252238),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _status,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF777386),
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          if (_isRecording)
            Text(
              _formatDuration(_recordingDuration),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF6C63FF),
              ),
            ),

          const SizedBox(height: 20),

          if (!_isRecording && !_isProcessing)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.mic_rounded),
                label: const Text(
                  'Start Recording',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

          if (_isRecording)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPaused
                        ? _resumeRecording
                        : _pauseRecording,
                    icon: Icon(
                      _isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                    ),
                    label: Text(
                      _isPaused ? 'Resume' : 'Pause',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      side: const BorderSide(
                        color: Color(0xFF6C63FF),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _stopRecording,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE54865),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PROCESSING CARD
  // ------------------------------------------------------------

  Widget _buildProcessingCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(
            color: Color(0xFF6C63FF),
          ),
          SizedBox(height: 16),
          Text(
            'Understanding the consultation...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF252238),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'SMRITI is extracting the relevant instructions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF777386),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // ANALYSIS SECTION
  // ------------------------------------------------------------

  Widget _buildAnalysisSection() {
    final data = _analysis!;

    final transcript =
        data['transcript']?.toString() ?? '';

    final doctorName =
    data['doctorName']?.toString();

    final healthIssue =
    data['healthIssue']?.toString();

    final medicines =
    _toList(data['medicines']);

    final tests =
    _toStringList(data['tests']);

    final precautions =
    _toStringList(data['precautions']);

    final foodRestrictions =
    _toStringList(data['foodRestrictions']);

    final followUp =
    data['followUp']?.toString();

    final warningSigns =
    _toStringList(data['warningSigns']);

    final otherInstructions =
    _toStringList(data['otherInstructions']);

    final unclear =
    _toStringList(data['unclear']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Consultation Understanding',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF252238),
          ),
        ),

        const SizedBox(height: 14),

        if (doctorName != null &&
            doctorName.isNotEmpty &&
            doctorName != 'null')
          _buildInfoCard(
            icon: Icons.person_outline_rounded,
            title: 'Healthcare Professional',
            child: Text(
              doctorName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        if (healthIssue != null &&
            healthIssue.isNotEmpty &&
            healthIssue != 'null')
          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            title: 'Health Issue Mentioned',
            child: Text(
              healthIssue,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),

        if (medicines.isNotEmpty)
          _buildMedicinesCard(medicines),

        if (tests.isNotEmpty)
          _buildListCard(
            icon: Icons.science_outlined,
            title: 'Tests Mentioned',
            items: tests,
          ),

        if (precautions.isNotEmpty)
          _buildListCard(
            icon: Icons.shield_outlined,
            title: 'Precautions',
            items: precautions,
          ),

        if (foodRestrictions.isNotEmpty)
          _buildListCard(
            icon: Icons.restaurant_outlined,
            title: 'Food Restrictions',
            items: foodRestrictions,
          ),

        if (followUp != null &&
            followUp.isNotEmpty &&
            followUp != 'null')
          _buildInfoCard(
            icon: Icons.calendar_month_outlined,
            title: 'Follow-up',
            child: Text(
              followUp,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),

        if (warningSigns.isNotEmpty)
          _buildListCard(
            icon: Icons.warning_amber_rounded,
            title: 'Warning Signs Mentioned',
            items: warningSigns,
          ),

        if (otherInstructions.isNotEmpty)
          _buildListCard(
            icon: Icons.notes_rounded,
            title: 'Other Instructions',
            items: otherInstructions,
          ),

        if (unclear.isNotEmpty)
          _buildListCard(
            icon: Icons.help_outline_rounded,
            title: 'Needs Clarification',
            items: unclear,
            isWarning: true,
          ),

        if (transcript.isNotEmpty)
          _buildTranscriptCard(transcript),

        const SizedBox(height: 12),

        _buildSafetyNote(),
      ],
    );
  }

  // ------------------------------------------------------------
  // MEDICINES
  // ------------------------------------------------------------

  Widget _buildMedicinesCard(List<dynamic> medicines) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8E5F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.medication_outlined,
                color: Color(0xFF6C63FF),
              ),
              SizedBox(width: 10),
              Text(
                'Medicines Mentioned',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF252238),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ...medicines.map(
                (medicine) {
              if (medicine is! Map) {
                return const SizedBox.shrink();
              }

              final name =
                  medicine['name']?.toString() ?? 'Medicine';

              final dose =
              medicine['dose']?.toString();

              final frequency =
              medicine['frequency']?.toString();

              final timing =
              _toStringList(medicine['timing']);

              final duration =
              medicine['duration']?.toString();

              final notes =
              medicine['notes']?.toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF252238),
                      ),
                    ),

                    if (_validText(dose))
                      _detailRow('Dose', dose!),

                    if (_validText(frequency))
                      _detailRow(
                        'Frequency',
                        frequency!,
                      ),

                    if (timing.isNotEmpty)
                      _detailRow(
                        'Timing',
                        timing.join(', '),
                      ),

                    if (_validText(duration))
                      _detailRow(
                        'Duration',
                        duration!,
                      ),

                    if (_validText(notes))
                      _detailRow(
                        'Notes',
                        notes!,
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DETAIL ROW
  // ------------------------------------------------------------

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF55515F),
            fontSize: 14,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$title: ',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF302C3A),
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // LIST CARD
  // ------------------------------------------------------------

  Widget _buildListCard({
    required IconData icon,
    required String title,
    required List<String> items,
    bool isWarning = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWarning
              ? const Color(0xFFFFD6A0)
              : const Color(0xFFE8E5F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: isWarning
                    ? const Color(0xFFE58A00)
                    : const Color(0xFF6C63FF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF252238),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...items.map(
                (item) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.circle,
                      size: 6,
                      color: Color(0xFF6C63FF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: Color(0xFF55515F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INFO CARD
  // ------------------------------------------------------------

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8E5F0),
        ),
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
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF252238),
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

  // ------------------------------------------------------------
  // TRANSCRIPT
  // ------------------------------------------------------------

  Widget _buildTranscriptCard(String transcript) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8E5F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.subject_rounded,
                color: Color(0xFF6C63FF),
              ),
              SizedBox(width: 10),
              Text(
                'Consultation Transcript',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF252238),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(
              transcript,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF4F4A59),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SAFETY NOTE
  // ------------------------------------------------------------

  Widget _buildSafetyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.verified_user_outlined,
            color: Color(0xFF6C63FF),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'SMRITI organizes what was said during the consultation. It does not diagnose conditions, change prescriptions, or decide medical treatment.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF514B6A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  List<dynamic> _toList(dynamic value) {
    if (value is List) {
      return value;
    }

    return [];
  }

  List<String> _toStringList(dynamic value) {
    if (value is! List) {
      return [];
    }

    return value
        .map((item) => item.toString())
        .where(
          (item) =>
      item.trim().isNotEmpty &&
          item != 'null',
    )
        .toList();
  }

  bool _validText(String? value) {
    return value != null &&
        value.trim().isNotEmpty &&
        value != 'null';
  }
}