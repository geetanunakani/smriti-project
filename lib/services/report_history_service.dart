import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/report_analysis.dart';

class ReportHistoryEntry {
  final String id;
  final String userIdentifier;
  final String savedAt;
  final String originalFilePath;
  final String originalFileName;
  final Map<String, dynamic> analysisJson;

  const ReportHistoryEntry({
    required this.id,
    required this.userIdentifier,
    required this.savedAt,
    required this.originalFilePath,
    required this.originalFileName,
    required this.analysisJson,
  });

  ReportAnalysis get analysis => ReportAnalysis.fromJson(analysisJson);

  factory ReportHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ReportHistoryEntry(
      id: json['id']?.toString() ?? '',
      userIdentifier: json['userIdentifier']?.toString() ?? '',
      savedAt: json['savedAt']?.toString() ?? '',
      originalFilePath: json['originalFilePath']?.toString() ?? '',
      originalFileName: json['originalFileName']?.toString() ?? 'Report',
      analysisJson: Map<String, dynamic>.from(
        json['analysis'] as Map? ?? const {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userIdentifier': userIdentifier,
    'savedAt': savedAt,
    'originalFilePath': originalFilePath,
    'originalFileName': originalFileName,
    'analysis': analysisJson,
  };
}

class ReportHistoryService {
  ReportHistoryService._();

  static final ReportHistoryService instance = ReportHistoryService._();

  Future<Directory> _userDirectory(String userIdentifier) async {
    final appDir = await getApplicationDocumentsDirectory();
    // Encode the identifier so it is safe to use as a folder name.
    final key = base64Url.encode(utf8.encode(userIdentifier.trim().toLowerCase()))
        .replaceAll('=', '');
    final dir = Directory('${appDir.path}/smriti_report_history/$key');
    await dir.create(recursive: true);
    return dir;
  }

  Future<File> _indexFile(String userIdentifier) async {
    final dir = await _userDirectory(userIdentifier);
    return File('${dir.path}/history.json');
  }

  Future<List<ReportHistoryEntry>> getReports(String userIdentifier) async {
    final index = await _indexFile(userIdentifier);
    if (!await index.exists()) return [];

    try {
      final decoded = jsonDecode(await index.readAsString());
      if (decoded is! List) return [];
      final entries = decoded
          .whereType<Map>()
          .map((e) => ReportHistoryEntry.fromJson(
        Map<String, dynamic>.from(e),
      ))
          .where((e) =>
      e.userIdentifier.trim().toLowerCase() ==
          userIdentifier.trim().toLowerCase())
          .toList();
      entries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReport({
    required String userIdentifier,
    required File sourceFile,
    required ReportAnalysis analysis,
  }) async {
    final dir = await _userDirectory(userIdentifier);
    final now = DateTime.now();
    final id = '${now.microsecondsSinceEpoch}';
    final extension = sourceFile.path.contains('.')
        ? '.${sourceFile.path.split('.').last.toLowerCase()}'
        : '.file';
    final originalName = sourceFile.uri.pathSegments.isNotEmpty
        ? Uri.decodeComponent(sourceFile.uri.pathSegments.last)
        : 'medical_report$extension';
    final storedFile = File('${dir.path}/$id$extension');
    await sourceFile.copy(storedFile.path);

    final entries = await getReports(userIdentifier);
    final entry = ReportHistoryEntry(
      id: id,
      userIdentifier: userIdentifier.trim().toLowerCase(),
      savedAt: now.toIso8601String(),
      originalFilePath: storedFile.path,
      originalFileName: originalName,
      analysisJson: _analysisToJson(analysis),
    );

    final index = await _indexFile(userIdentifier);
    await index.writeAsString(
      jsonEncode([entry.toJson(), ...entries.map((e) => e.toJson())]),
      flush: true,
    );
  }

  Map<String, dynamic> _analysisToJson(ReportAnalysis a) => {
    'reportType': a.reportType,
    'reportDate': a.reportDate,
    'summary': a.summary,
    'values': a.values
        .map((v) => {
      'name': v.name,
      'value': v.value,
      'unit': v.unit,
      'referenceRange': v.referenceRange,
      'status': v.status.name,
      'meaning': v.meaning,
    })
        .toList(),
    'attention': a.attention,
    'questionsForDoctor': a.questionsForDoctor,
    'nextSteps': a.nextSteps,
    'unclear': a.unclear,
    'urgency': a.urgency.name,
    'urgencyReason': a.urgencyReason,
  };
}
