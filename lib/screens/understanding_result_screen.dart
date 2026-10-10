
import 'package:flutter/material.dart';

import '../models/visit_record.dart';
import '../services/care_record_pdf_service.dart';
import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
class UnderstandingResultScreen extends StatefulWidget {
  final Map<String, dynamic> doctorAnalysis;
  final String patientResponse;
  final String sourceType;
  final int? quizScore;
  final int? totalQuestions;

  // AI semantic teach-back result from Gemini
  final TeachBackResult? teachBackResult;

  const UnderstandingResultScreen({
    super.key,
    required this.doctorAnalysis,
    required this.patientResponse,
    required this.sourceType,
    this.quizScore,
    this.totalQuestions,
    this.teachBackResult,
  });

  @override
  State<UnderstandingResultScreen> createState() =>
      _UnderstandingResultScreenState();
}

class _UnderstandingResultScreenState
    extends State<UnderstandingResultScreen> {
  bool _generatingPdf = false;
  File? _generatedPdfFile;

  // ==========================================================================
  // GENERATE SMRITI CARE RECORD
  // ==========================================================================

  Future<void> _generateCareRecord() async {
    final result = widget.teachBackResult;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Care Record can be generated after understanding verification.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _generatingPdf = true;
    });

    try {
      final visit = VisitRecord.fromAi(
        widget.doctorAnalysis,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        number: 1,
        date: DateTime.now(),
        language: 'English',
        audioPath: null,
      );

      final pdfFile =
      await CareRecordPdfService.generateCareRecord(
        visit: visit,
        teachBackResult: result,
      );

      if (!mounted) return;

      setState(() {
        _generatedPdfFile = pdfFile;
      });

      final fileName = pdfFile.path.split(RegExp(r'[/\\]')).last;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text(
            'Care Record created: $fileName',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text(
            'Could not create Care Record: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _generatingPdf = false;
        });
      }
    }
  }
  Future<void> _openCareRecord() async {
    final file = _generatedPdfFile;

    if (file == null || !await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please generate the Care Record first.',
          ),
        ),
      );
      return;
    }

    final result = await OpenFilex.open(
      file.path,
      type: 'application/pdf',
    );

    if (!mounted) return;

    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open PDF: ${result.message}',
          ),
        ),
      );
    }
  }
  Future<void> _shareCareRecord() async {
    final file = _generatedPdfFile;

    if (file == null || !await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please generate the Care Record first.',
          ),
        ),
      );
      return;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: 'SMRITI Care Record',
          text: 'SMRITI Care Record',
          files: [
            XFile(file.path),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not share PDF: $e',
          ),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final isQuiz = widget.sourceType == 'quiz';
    final hasTeachBack = widget.teachBackResult != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),

      // ======================================================================
      // APP BAR
      // ======================================================================

      appBar: AppBar(
        title: const Text('Understanding Result'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),

      // ======================================================================
      // BODY
      // ======================================================================

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const SizedBox(height: 15),

              // =================================================================
              // ICON
              // =================================================================

              Container(
                width: 85,
                height: 85,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEDE9FE),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 48,
                  color: Color(0xFF7C3AED),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================================
              // TITLE
              // =================================================================

              const Text(
                'Understanding Review',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                hasTeachBack
                    ? 'SMRITI compared the patient\'s response with the recorded healthcare instructions.'
                    : 'SMRITI has captured the patient\'s response. The next step is to verify whether it matches the recorded instructions.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              // ================================================================
              // AI TEACH-BACK RESULT
              // ================================================================

              if (hasTeachBack) ...[
                _ScoreCard(
                  score: widget.teachBackResult!.score,
                  hasMismatch: widget.teachBackResult!.hasMismatch,
                ),

                const SizedBox(height: 18),

                _InfoCard(
                  title: 'AI Summary',
                  child: Text(
                    widget.teachBackResult!.summary,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Comparison heading
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Instruction Comparison',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Every instruction comparison
                ...widget.teachBackResult!.items.map(
                      (item) => _TeachBackItemCard(item: item),
                ),

                const SizedBox(height: 18),

                // Human confirmation banner
                _HumanConfirmationCard(
                  hasMismatch: widget.teachBackResult!.hasMismatch,
                ),
              ]

              // ================================================================
              // OLD QUIZ RESULT
              // ================================================================

              else ...[
                if (isQuiz &&
                    widget.quizScore != null &&
                    widget.totalQuestions != null)
                  _InfoCard(
                    title: 'Understanding Check',
                    child: Text(
                      '${widget.quizScore} / ${widget.totalQuestions} responses matched the recorded instructions.',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                _InfoCard(
                  title: 'Patient Response',
                  child: Text(
                    widget.patientResponse.isEmpty
                        ? 'No response captured.'
                        : widget.patientResponse,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const _InfoCard(
                  title: 'Important',
                  child: Text(
                    'This result does not diagnose a condition or decide whether a prescription is medically correct. It only helps identify possible differences between the recorded instructions and the patient\'s understanding.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                const _HumanConfirmationCard(
                  hasMismatch: true,
                ),
              ],

              const SizedBox(height: 25),

              // =================================================================
              // SAFETY NOTE
              // =================================================================

              _InfoCard(
                title: 'Safety',
                child: const Text(
                  'SMRITI does not diagnose conditions, prescribe medicines, change dosages, or replace a healthcare professional. It only helps identify possible differences between recorded instructions and patient understanding.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // =================================================================
              // SMRITI CARE RECORD
              // =================================================================

              if (hasTeachBack) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE9D5FF),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Color(0xFF7C3AED),
                            size: 24,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'SMRITI Care Record',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Create a PDF containing the consultation, recorded instructions, patient understanding, and verification result.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed:
                          _generatingPdf ? null : _generateCareRecord,
                          icon: _generatingPdf
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(
                            Icons.picture_as_pdf_outlined,
                          ),
                          label: Text(
                            _generatingPdf
                                ? 'Creating Care Record...'
                                : 'Generate SMRITI Care Record',
                          ),

                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7C3AED),
                            side: const BorderSide(
                              color: Color(0xFF7C3AED),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),

                      if (_generatedPdfFile != null) ...[
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openCareRecord,
                                icon: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                ),
                                label: const Text('Open PDF'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF7C3AED),
                                  side: const BorderSide(
                                    color: Color(0xFF7C3AED),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _shareCareRecord,
                                icon: const Icon(Icons.share_rounded),
                                label: const Text('Share PDF'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7C3AED),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),
              ],

              // =================================================================
              // CONTINUE BUTTON
              // =================================================================

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                          (route) => route.isFirst,
                    );
                  },
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
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SCORE CARD
// ============================================================================

class _ScoreCard extends StatelessWidget {
  final int score;
  final bool hasMismatch;

  const _ScoreCard({
    required this.score,
    required this.hasMismatch,
  });

  @override
  Widget build(BuildContext context) {
    final Color scoreColor;

    if (score >= 80 && !hasMismatch) {
      scoreColor = Colors.green;
    } else if (score >= 50) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Understanding Score',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            '$score%',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: scoreColor,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            hasMismatch
                ? 'Possible differences detected'
                : 'Response is consistent with the recorded instructions',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: scoreColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TEACH-BACK ITEM CARD
// ============================================================================

class _TeachBackItemCard extends StatelessWidget {
  final TeachBackItem item;

  const _TeachBackItemCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(item.status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusInfo.color.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topic + status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.topic,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusInfo.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusInfo.label,
                  style: TextStyle(
                    color: statusInfo.color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Doctor said
          _ComparisonSection(
            icon: Icons.medical_information_outlined,
            title: 'Recorded instruction',
            text: item.doctorSaid,
          ),

          const SizedBox(height: 14),

          // Patient said
          _ComparisonSection(
            icon: Icons.person_outline,
            title: 'Patient understood',
            text: item.patientSaid == null ||
                item.patientSaid!.trim().isEmpty
                ? 'Not mentioned'
                : item.patientSaid!,
          ),

          // AI note
          if (item.note.trim().isNotEmpty) ...[
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusInfo.backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                item.note,
                style: TextStyle(
                  fontSize: 13,
                  color: statusInfo.color,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// COMPARISON SECTION
// ============================================================================

class _ComparisonSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _ComparisonSection({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF7C3AED),
            ),

            const SizedBox(width: 7),

            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// HUMAN CONFIRMATION CARD
// ============================================================================

class _HumanConfirmationCard extends StatelessWidget {
  final bool hasMismatch;

  const _HumanConfirmationCard({
    required this.hasMismatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFF59E0B),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFFD97706),
              ),

              const SizedBox(width: 8),

              Text(
                hasMismatch
                    ? 'Human confirmation needed'
                    : 'Human confirmation',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            hasMismatch
                ? 'SMRITI found one or more possible differences. The relevant instruction should be re-confirmed with the healthcare professional or pharmacist.'
                : 'SMRITI found the response consistent with the recorded instructions. Human confirmation remains available whenever there is uncertainty.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATUS INFORMATION
// ============================================================================

class _StatusInfo {
  final String label;
  final Color color;
  final Color backgroundColor;

  const _StatusInfo({
    required this.label,
    required this.color,
    required this.backgroundColor,
  });
}

_StatusInfo _getStatusInfo(MatchStatus status) {
  switch (status) {
    case MatchStatus.matched:
      return const _StatusInfo(
        label: 'Matched',
        color: Color(0xFF15803D),
        backgroundColor: Color(0xFFDCFCE7),
      );

    case MatchStatus.partial:
      return const _StatusInfo(
        label: 'Possible difference',
        color: Color(0xFFD97706),
        backgroundColor: Color(0xFFFEF3C7),
      );

    case MatchStatus.missed:
      return const _StatusInfo(
        label: 'Not mentioned',
        color: Color(0xFFD97706),
        backgroundColor: Color(0xFFFEF3C7),
      );

    case MatchStatus.conflict:
      return const _StatusInfo(
        label: 'Possible conflict',
        color: Color(0xFFDC2626),
        backgroundColor: Color(0xFFFEE2E2),
      );
  }
}

// ============================================================================
// INFO CARD
// ============================================================================

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF7C3AED),
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          child,
        ],
      ),
    );
  }
}
