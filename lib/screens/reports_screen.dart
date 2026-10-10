import 'dart:io';

import 'package:flutter/material.dart';

import '../models/report_analysis.dart';
import '../services/auth_service.dart';
import '../services/report_history_service.dart';
import '../theme.dart';

class ReportsScreen extends StatefulWidget {
  final SmritiUser user;

  const ReportsScreen({super.key, required this.user});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<ReportHistoryEntry>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _reportsFuture =
        ReportHistoryService.instance.getReports(widget.user.identifier);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _reportsFuture;
  }

  String _date(String raw) {
    final date = DateTime.tryParse(raw)?.toLocal();
    if (date == null) return 'Date unavailable';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmritiColors.blush,
      appBar: AppBar(
        title: const Text('Report History',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: SmritiColors.blush,
        foregroundColor: SmritiColors.plum,
        elevation: 0,
      ),
      body: FutureBuilder<List<ReportHistoryEntry>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load report history. Please try again.'),
            );
          }
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.folder_open_rounded,
                        size: 64, color: SmritiColors.rose),
                    const SizedBox(height: 16),
                    const Text('No saved reports yet',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: SmritiColors.plum)),
                    const SizedBox(height: 8),
                    const Text(
                      'After a report is analyzed successfully, it will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: SmritiColors.ink, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Analyze a report'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = reports[index];
                final analysis = entry.analysis;
                return Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF8E5ED),
                      child: Icon(Icons.description_rounded,
                          color: SmritiColors.rose),
                    ),
                    title: Text(
                      analysis.reportType,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: SmritiColors.plum),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${_date(entry.savedAt)} · ${analysis.values.length} test values\n'
                            '${analysis.abnormalCount} value(s) outside printed range',
                        style: const TextStyle(height: 1.45),
                      ),
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _SavedReportDetail(
                          entry: entry,
                          dateLabel: _date(entry.savedAt),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SavedReportDetail extends StatelessWidget {
  final ReportHistoryEntry entry;
  final String dateLabel;

  const _SavedReportDetail({
    required this.entry,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ReportAnalysis report = entry.analysis;
    return Scaffold(
      backgroundColor: SmritiColors.blush,
      appBar: AppBar(
        title: const Text('Saved report'),
        backgroundColor: SmritiColors.blush,
        foregroundColor: SmritiColors.plum,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(report.reportType,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: SmritiColors.plum)),
          const SizedBox(height: 4),
          Text('Saved $dateLabel'),
          const SizedBox(height: 16),
          _panel('In simple words', report.summary),
          if (report.attention.isNotEmpty)
            _panel('Needs your attention', report.attention.join('\n• ')),
          if (report.values.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Test values',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: SmritiColors.plum)),
            ),
            for (final v in report.values)
              _panel(
                '${v.name} · ${v.status.name.toUpperCase()}',
                '${v.display.isEmpty ? '-' : v.display}'
                    '${v.referenceRange == null ? '' : '\nRange on report: ${v.referenceRange}'}'
                    '${v.meaning.isEmpty ? '' : '\n${v.meaning}'}',
              ),
          ],
          if (report.questionsForDoctor.isNotEmpty)
            _panel('Questions for your doctor',
                '• ${report.questionsForDoctor.join('\n• ')}'),
          if (report.nextSteps.isNotEmpty)
            _panel('Next steps', '• ${report.nextSteps.join('\n• ')}'),
          if (report.unclear.isNotEmpty)
            _panel('Could not read clearly', '• ${report.unclear.join('\n• ')}'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final file = File(entry.originalFilePath);
              if (!await file.exists()) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Original report file not found.')),
                );
                return;
              }
              // For now, confirm the stored copy exists. A viewer can be added
              // separately based on the file type and desired UX.
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Original saved as ${entry.originalFileName}')),
              );
            },
            icon: const Icon(Icons.description_outlined),
            label: const Text('Check original report'),
          ),
          const SizedBox(height: 10),
          const Text(
            'This saved explanation is not a diagnosis. Discuss medical findings with your healthcare professional.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SmritiColors.mauve, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _panel(String title, String body) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: SmritiColors.plum)),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(height: 1.45)),
      ],
    ),
  );
}
