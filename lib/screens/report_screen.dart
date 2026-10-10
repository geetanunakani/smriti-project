import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/report_analysis.dart';
import '../services/auth_service.dart';
import '../services/gemini_service.dart';
import '../services/report_history_service.dart';
import 'reports_screen.dart';
import '../theme.dart';

const _amber = Color(0xFFB26A00);
const _red = Color(0xFFB3261E);
const _green = Color(0xFF2E7D32);

class ReportScreen extends StatefulWidget {
  final SmritiUser user;

  const ReportScreen({
    super.key,
    required this.user,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  File? _file;
  bool _loading = false;
  String? _error;
  ReportAnalysis? _result;

  Future<void> _pickReport() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _file = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
        ],
      );

      // file_picker 13.1.0 returns List<PlatformFile> directly.
      if (result.isEmpty) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        return;
      }

      final path = result.single.path;

      if (path == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _error = 'Could not access the selected file.';
        });

        return;
      }

      final file = File(path);

      setState(() {
        _file = file;
      });

      final analysis = await GeminiService.instance.analyzeReport(
        file,
        language: 'English',
      );

      if (!mounted) return;

      await ReportHistoryService.instance.saveReport(
        userIdentifier: widget.user.identifier,
        sourceFile: file,
        analysis: analysis,
      );

      if (!mounted) return;

      setState(() {
        _result = analysis;
        _loading = false;
      });
    } on AiException catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not analyze this report. Please try again.';
      });
    }
  }

  void _reset() {
    setState(() {
      _file = null;
      _result = null;
      _error = null;
    });
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
          'Report analysis',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Report history',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportsScreen(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? _buildLoading()
            : _result != null
            ? _buildResult(_result!)
            : _buildPicker(),
      ),
    );
  }

  Widget _buildPicker() {
    return Padding(
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
                Icon(
                  Icons.document_scanner_rounded,
                  size: 34,
                  color: SmritiColors.rose,
                ),
                SizedBox(height: 10),
                Text(
                  'Analyze a medical report',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: SmritiColors.plum,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Upload a clear PDF or image of your medical report. '
                      'SMRITI will extract the reported values, explain them '
                      'in simple words, and show which values are outside '
                      'the range printed on the report.',
                  style: TextStyle(
                    height: 1.4,
                    color: SmritiColors.ink,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: SmritiColors.rose,
              ),
              onPressed: _pickReport,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text(
                'Upload report',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Center(
            child: Text(
              'Supported: PDF, JPG, JPEG, PNG',
              style: TextStyle(
                color: SmritiColors.mauve,
                fontSize: 12,
              ),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: _red,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: _red,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          const Center(
            child: Text(
              'SMRITI explains reports. It does not diagnose or prescribe.',
              style: TextStyle(
                color: SmritiColors.mauve,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_file != null &&
                !_file!.path.toLowerCase().endsWith('.pdf'))
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _file!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 24),

            const CircularProgressIndicator(
              color: SmritiColors.rose,
            ),

            const SizedBox(height: 18),

            const Text(
              'Reading your report...',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: SmritiColors.plum,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'SMRITI is extracting the information from your report.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: SmritiColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(ReportAnalysis r) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Text(
          r.reportType,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: SmritiColors.plum,
          ),
        ),

        if (r.reportDate != null)
          Text(
            r.reportDate!,
            style: const TextStyle(
              color: SmritiColors.ink,
            ),
          ),

        const SizedBox(height: 14),

        _urgencyBanner(r),

        const SizedBox(height: 14),

        _card(
          title: 'In simple words',
          child: Text(
            r.summary,
            style: const TextStyle(
              height: 1.5,
              color: SmritiColors.ink,
            ),
          ),
        ),

        if (r.attention.isNotEmpty)
          _card(
            title: 'Needs your attention',
            child: _bullets(
              r.attention,
              Icons.error_outline_rounded,
              _amber,
            ),
          ),

        if (r.values.isNotEmpty) ...[
          const SizedBox(height: 4),

          Text(
            'Test values',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: SmritiColors.plum,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '${r.abnormalCount} value(s) outside the printed range',
            style: const TextStyle(
              color: SmritiColors.mauve,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 10),

          for (final v in r.values)
            _ValueTile(v: v),
        ],

        if (r.questionsForDoctor.isNotEmpty)
          _card(
            title: 'Questions for your doctor',
            child: _bullets(
              r.questionsForDoctor,
              Icons.chat_bubble_outline_rounded,
              SmritiColors.rose,
            ),
          ),

        if (r.nextSteps.isNotEmpty)
          _card(
            title: 'Next steps',
            child: _bullets(
              r.nextSteps,
              Icons.check_circle_outline_rounded,
              _green,
            ),
          ),

        if (r.unclear.isNotEmpty)
          _card(
            title: 'Could not read clearly',
            child: _bullets(
              r.unclear,
              Icons.visibility_off_outlined,
              SmritiColors.ink,
            ),
          ),

        const SizedBox(height: 8),

        const Text(
          'This is a simple explanation of your report, not a diagnosis. '
              'Only your healthcare professional can interpret the findings '
              'in your personal medical context.',
          style: TextStyle(
            color: SmritiColors.mauve,
            fontSize: 12,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: SmritiColors.plum,
              side: const BorderSide(
                color: SmritiColors.rose,
              ),
            ),
            onPressed: _reset,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Analyze another report'),
          ),
        ),
      ],
    );
  }

  Widget _urgencyBanner(ReportAnalysis r) {
    Color color;
    IconData icon;
    String title;

    switch (r.urgency) {
      case Urgency.urgent:
        color = _red;
        icon = Icons.priority_high_rounded;
        title = 'Report marked for urgent attention';
        break;

      case Urgency.soon:
        color = _amber;
        icon = Icons.schedule_rounded;
        title = 'Show this report to your doctor soon';
        break;

      case Urgency.routine:
        color = _green;
        icon = Icons.check_rounded;
        title = 'Keep this report for your next visit';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (r.urgencyReason != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    r.urgencyReason!,
                    style: const TextStyle(
                      color: SmritiColors.ink,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: SmritiColors.plum,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _bullets(
      List<String> items,
      IconData icon,
      Color color,
      ) {
    return Column(
      children: [
        for (final text in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
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
          ),
      ],
    );
  }
}

class _ValueTile extends StatelessWidget {
  final ReportValue v;

  const _ValueTile({
    required this.v,
  });

  Color get _color {
    switch (v.status) {
      case ValueStatus.critical:
        return _red;

      case ValueStatus.low:
      case ValueStatus.high:
        return _amber;

      case ValueStatus.normal:
        return _green;

      case ValueStatus.unknown:
        return SmritiColors.ink;
    }
  }

  String get _label {
    switch (v.status) {
      case ValueStatus.critical:
        return 'CRITICAL';

      case ValueStatus.low:
        return 'LOW';

      case ValueStatus.high:
        return 'HIGH';

      case ValueStatus.normal:
        return 'NORMAL';

      case ValueStatus.unknown:
        return 'NO RANGE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: v.isAbnormal
            ? Border.all(
          color: _color.withValues(alpha: 0.5),
        )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  v.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: SmritiColors.plum,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _label,
                  style: TextStyle(
                    color: _color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            v.display.isEmpty ? '-' : v.display,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _color,
            ),
          ),

          if (v.referenceRange != null)
            Text(
              'Range on report: ${v.referenceRange}',
              style: const TextStyle(
                fontSize: 12,
                color: SmritiColors.mauve,
              ),
            ),

          if (v.meaning.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              v.meaning,
              style: const TextStyle(
                height: 1.4,
                color: SmritiColors.ink,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}