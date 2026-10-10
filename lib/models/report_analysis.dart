String? _s(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  if (s.isEmpty || s.toLowerCase() == 'null') return null;
  return s;
}

List<String> _list(dynamic v) {
  if (v is String) return v.trim().isEmpty ? [] : [v.trim()];
  if (v is List) {
    return v
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty && e.toLowerCase() != 'null')
        .toList();
  }
  return [];
}

enum ValueStatus { low, normal, high, critical, unknown }

enum Urgency { routine, soon, urgent }

ValueStatus _status(String? s) {
  final t = (s ?? '').toLowerCase();
  if (t.startsWith('crit')) return ValueStatus.critical;
  if (t.startsWith('low')) return ValueStatus.low;
  if (t.startsWith('high')) return ValueStatus.high;
  if (t.startsWith('norm')) return ValueStatus.normal;
  return ValueStatus.unknown;
}

Urgency _urgency(String? s) {
  final t = (s ?? '').toLowerCase();
  if (t.startsWith('urg')) return Urgency.urgent;
  if (t.startsWith('soon')) return Urgency.soon;
  return Urgency.routine;
}

class ReportValue {
  final String name;
  final String? value, unit, referenceRange;
  final ValueStatus status;
  final String meaning;

  const ReportValue({
    required this.name,
    this.value,
    this.unit,
    this.referenceRange,
    required this.status,
    required this.meaning,
  });

  bool get isAbnormal =>
      status == ValueStatus.low ||
          status == ValueStatus.high ||
          status == ValueStatus.critical;

  String get display => [value, unit].whereType<String>().join(' ');

  factory ReportValue.fromJson(Map<String, dynamic> j) => ReportValue(
    name: _s(j['name']) ?? 'Test',
    value: _s(j['value']),
    unit: _s(j['unit']),
    referenceRange: _s(j['referenceRange']),
    status: _status(_s(j['status'])),
    meaning: _s(j['meaning']) ?? '',
  );
}

class ReportAnalysis {
  final String reportType;
  final String? reportDate;
  final String summary;
  final List<ReportValue> values;
  final List<String> attention, questionsForDoctor, nextSteps, unclear;
  final Urgency urgency;
  final String? urgencyReason;

  const ReportAnalysis({
    required this.reportType,
    this.reportDate,
    required this.summary,
    this.values = const [],
    this.attention = const [],
    this.questionsForDoctor = const [],
    this.nextSteps = const [],
    this.unclear = const [],
    this.urgency = Urgency.routine,
    this.urgencyReason,
  });

  int get abnormalCount => values.where((v) => v.isAbnormal).length;

  factory ReportAnalysis.fromJson(Map<String, dynamic> j) => ReportAnalysis(
    reportType: _s(j['reportType']) ?? 'Medical report',
    reportDate: _s(j['reportDate']),
    summary: _s(j['summary']) ?? '',
    values: (j['values'] as List? ?? [])
        .whereType<Map>()
        .map((m) => ReportValue.fromJson(Map<String, dynamic>.from(m)))
        .toList(),
    attention: _list(j['attention']),
    questionsForDoctor: _list(j['questionsForDoctor']),
    nextSteps: _list(j['nextSteps']),
    unclear: _list(j['unclear']),
    urgency: _urgency(_s(j['urgency'])),
    urgencyReason: _s(j['urgencyReason']),
  );

  /// Sample data so the UI works without an API key.
  static const demo = ReportAnalysis(
    reportType: 'Blood test (sample data)',
    reportDate: '28 Sep 2026',
    summary:
    'This blood test checked your blood count and sugar. Most values are '
        'inside the normal range. Two values are outside the range printed '
        'on the report: haemoglobin is lower and fasting glucose is higher.',
    values: [
      ReportValue(
        name: 'Haemoglobin',
        value: '10.2',
        unit: 'g/dL',
        referenceRange: '12.0 - 15.5',
        status: ValueStatus.low,
        meaning:
        'Haemoglobin carries oxygen in your blood. A lower value is '
            'commonly linked with low iron or other causes. Only your '
            'doctor can find the reason.',
      ),
      ReportValue(
        name: 'White blood cells',
        value: '7,200',
        unit: '/uL',
        referenceRange: '4,000 - 11,000',
        status: ValueStatus.normal,
        meaning: 'These cells fight infection. Your value is in the normal range.',
      ),
      ReportValue(
        name: 'Platelets',
        value: '2.4',
        unit: 'lakh/uL',
        referenceRange: '1.5 - 4.5',
        status: ValueStatus.normal,
        meaning: 'Platelets help blood to clot. Your value is in the normal range.',
      ),
      ReportValue(
        name: 'Fasting glucose',
        value: '118',
        unit: 'mg/dL',
        referenceRange: '70 - 100',
        status: ValueStatus.high,
        meaning:
        'This shows the sugar level in your blood after fasting. A higher '
            'value is sometimes seen when the body is handling sugar '
            'differently. Only your doctor can confirm what it means for you.',
      ),
    ],
    attention: [
      'Haemoglobin is below the printed range.',
      'Fasting glucose is above the printed range.',
    ],
    questionsForDoctor: [
      'What could be the reason for my low haemoglobin?',
      'Do I need to repeat the glucose test?',
      'Should I change anything in my food or routine?',
    ],
    nextSteps: [
      'Show this report to your doctor.',
      'Carry the original report to your next visit.',
    ],
    urgency: Urgency.soon,
    urgencyReason: 'Two values are outside the printed range.',
  );
}