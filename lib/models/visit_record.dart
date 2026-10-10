import 'dart:convert';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 'తెలుగు (Telugu)' -> 'Telugu'
String langName(String l) {
  if (l.contains('Telugu')) return 'Telugu';
  if (l.contains('Hindi')) return 'Hindi';
  return 'English';
}

List<String> _strList(dynamic v) {
  if (v is String) return v.trim().isEmpty ? [] : [v.trim()];
  if (v is List) {
    return v
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty && e.toLowerCase() != 'null')
        .toList();
  }
  return [];
}

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty || s.toLowerCase() == 'null') return null;
  return s;
}

class Medicine {
  final String name;
  final String? dose, frequency, duration, notes;
  final List<String> timing;

  const Medicine({
    required this.name,
    this.dose,
    this.frequency,
    this.duration,
    this.notes,
    this.timing = const [],
  });

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
    name: _str(j['name']) ?? 'Medicine (name not clear)',
    dose: _str(j['dose']),
    frequency: _str(j['frequency']),
    duration: _str(j['duration']),
    notes: _str(j['notes']),
    timing: _strList(j['timing']),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'dose': dose,
    'frequency': frequency,
    'timing': timing,
    'duration': duration,
    'notes': notes,
  };
}

/// One consultation, structured from what the healthcare professional said.
/// Nothing here is invented by the AI: missing info stays empty.
class VisitRecord {
  final String id;
  final int visitNumber;
  final DateTime date;
  final String language; // patient's preferred language
  final String transcript;
  final String? doctorName;
  final String healthIssue;
  final List<Medicine> medicines;
  final List<String> tests,
      precautions,
      foodRestrictions,
      warningSigns,
      otherInstructions,
      unclear;
  final String? followUp;
  final String? audioPath;

  bool verified;
  int? understandingScore;
  int? quizScore;

  VisitRecord({
    required this.id,
    required this.visitNumber,
    required this.date,
    required this.language,
    required this.transcript,
    required this.healthIssue,
    this.doctorName,
    this.medicines = const [],
    this.tests = const [],
    this.precautions = const [],
    this.foodRestrictions = const [],
    this.warningSigns = const [],
    this.otherInstructions = const [],
    this.unclear = const [],
    this.followUp,
    this.audioPath,
    this.verified = false,
    this.understandingScore,
    this.quizScore,
  });

  String get title => 'Doctor Visit $visitNumber';
  String get fileName => 'doctor_VISIT_${visitNumber}_${isoDate(date)}';

  factory VisitRecord.fromAi(
      Map<String, dynamic> j, {
        required String id,
        required int number,
        required DateTime date,
        required String language,
        String? audioPath,
      }) {
    final meds = (j['medicines'] is List)
        ? (j['medicines'] as List)
        .whereType<Map>()
        .map((m) => Medicine.fromJson(Map<String, dynamic>.from(m)))
        .toList()
        : <Medicine>[];
    return VisitRecord(
      id: id,
      visitNumber: number,
      date: date,
      language: language,
      transcript: _str(j['transcript']) ?? '',
      doctorName: _str(j['doctorName']),
      healthIssue: _str(j['healthIssue']) ?? 'Not clearly stated in the consultation.',
      medicines: meds,
      tests: _strList(j['tests']),
      precautions: _strList(j['precautions']),
      foodRestrictions: _strList(j['foodRestrictions']),
      warningSigns: _strList(j['warningSigns']),
      otherInstructions: _strList(j['otherInstructions']),
      unclear: _strList(j['unclear']),
      followUp: _str(j['followUp']),
      audioPath: audioPath,
    );
  }

  factory VisitRecord.fromJson(Map<String, dynamic> j) => VisitRecord(
    id: j['id'],
    visitNumber: j['visitNumber'],
    date: DateTime.parse(j['date']),
    language: j['language'] ?? 'English',
    transcript: j['transcript'] ?? '',
    doctorName: j['doctorName'],
    healthIssue: j['healthIssue'] ?? '',
    medicines: (j['medicines'] as List? ?? [])
        .map((m) => Medicine.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
    tests: _strList(j['tests']),
    precautions: _strList(j['precautions']),
    foodRestrictions: _strList(j['foodRestrictions']),
    warningSigns: _strList(j['warningSigns']),
    otherInstructions: _strList(j['otherInstructions']),
    unclear: _strList(j['unclear']),
    followUp: j['followUp'],
    audioPath: j['audioPath'],
    verified: j['verified'] ?? false,
    understandingScore: j['understandingScore'],
    quizScore: j['quizScore'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'visitNumber': visitNumber,
    'date': date.toIso8601String(),
    'language': language,
    'transcript': transcript,
    'doctorName': doctorName,
    'healthIssue': healthIssue,
    'medicines': medicines.map((m) => m.toJson()).toList(),
    'tests': tests,
    'precautions': precautions,
    'foodRestrictions': foodRestrictions,
    'warningSigns': warningSigns,
    'otherInstructions': otherInstructions,
    'unclear': unclear,
    'followUp': followUp,
    'audioPath': audioPath,
    'verified': verified,
    'understandingScore': understandingScore,
    'quizScore': quizScore,
  };

  /// Structured instructions only (no transcript) - used as AI context.
  String aiContext() {
    final m = toJson()
      ..remove('transcript')
      ..remove('audioPath')
      ..remove('id')
      ..remove('verified')
      ..remove('understandingScore')
      ..remove('quizScore');
    return jsonEncode(m);
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String doctorSaid;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.doctorSaid,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> j) => QuizQuestion(
    question: _str(j['question']) ?? '',
    options: _strList(j['options']),
    correctIndex: (j['correctIndex'] is int)
        ? j['correctIndex']
        : int.tryParse('${j['correctIndex']}') ?? 0,
    doctorSaid: _str(j['doctorSaid']) ?? '',
  );
}

enum MatchStatus { matched, partial, missed, conflict }

class TeachBackItem {
  final String topic;
  final String doctorSaid;
  final String? patientSaid;
  final MatchStatus status;
  final String note;

  const TeachBackItem({
    required this.topic,
    required this.doctorSaid,
    required this.patientSaid,
    required this.status,
    required this.note,
  });

  bool get needsReconfirm => status != MatchStatus.matched;

  factory TeachBackItem.fromJson(Map<String, dynamic> j) {
    final s = (_str(j['status']) ?? 'missed').toLowerCase();
    return TeachBackItem(
      topic: _str(j['topic']) ?? 'Instruction',
      doctorSaid: _str(j['doctorSaid']) ?? '',
      patientSaid: _str(j['patientSaid']),
      status: s.startsWith('match')
          ? MatchStatus.matched
          : s.startsWith('part')
          ? MatchStatus.partial
          : s.startsWith('conf')
          ? MatchStatus.conflict
          : MatchStatus.missed,
      note: _str(j['note']) ?? '',
    );
  }
}

class TeachBackResult {
  final int score;
  final String summary;
  final List<TeachBackItem> items;

  const TeachBackResult({
    required this.score,
    required this.summary,
    required this.items,
  });

  bool get hasMismatch => items.any((i) => i.needsReconfirm);

  factory TeachBackResult.fromJson(Map<String, dynamic> j) => TeachBackResult(
    score: (j['score'] is num) ? (j['score'] as num).round().clamp(0, 100) : 0,
    summary: _str(j['summary']) ?? '',
    items: (j['items'] as List? ?? [])
        .whereType<Map>()
        .map((m) => TeachBackItem.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
  );
}