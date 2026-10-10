import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/report_analysis.dart';
import '../models/visit_record.dart';

class AiException implements Exception {
  final String message;
  AiException(this.message);
  @override
  String toString() => message;
}

/// All AI work goes through here.
///
/// SAFETY RULE baked into every prompt: the AI only STRUCTURES what the
/// healthcare professional said. It never diagnoses, prescribes, changes
/// doses or says the doctor is wrong.
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  static const _safety = '''
STRICT RULES:
- Use ONLY information explicitly stated in the consultation. Never add, guess, correct or invent medicines, doses, diagnoses or advice.
- If something was not stated, use null or an empty list.
- Never say the doctor is wrong. Never suggest a different dose or medicine.
- Write in simple, patient-friendly language.
''';

  Future<Map<String, dynamic>> _generate(
      List<Map<String, dynamic>> parts, {
        double temperature = 0.1,
      }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
          '${AppConfig.geminiModel}:generateContent?key=${AppConfig.geminiApiKey}',
    );
    final http.Response res;
    try {
      res = await http
          .post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {'parts': parts}
          ],
          'generationConfig': {
            'temperature': temperature,
            'responseMimeType': 'application/json',
          },
        }),
      )
          .timeout(const Duration(minutes: 4));
    } on SocketException {
      throw AiException('No internet connection. Please check your network.');
    } catch (e) {
      throw AiException('Could not reach the AI service. ($e)');
    }

    if (res.statusCode != 200) {
      throw AiException('AI service error (${res.statusCode}). '
          'Check your API key and try again.');
    }
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final partsOut = body['candidates'][0]['content']['parts'] as List;
      final text = partsOut
          .where((p) => p['thought'] != true && p['text'] != null)
          .map((p) => p['text'].toString())
          .join();
      return _decode(text);
    } catch (_) {
      throw AiException('The AI response could not be read. Please try again.');
    }
  }

  Map<String, dynamic> _decode(String text) {
    var t = text.trim();
    if (t.startsWith('```')) {
      t = t
          .replaceFirst(RegExp(r'^```(?:json)?'), '')
          .replaceFirst(RegExp(r'```$'), '')
          .trim();
    }
    final d = jsonDecode(t);
    if (d is Map<String, dynamic>) return d;
    if (d is List) return {'items': d, 'questions': d};
    throw const FormatException('bad json');
  }

  // ---------------------------------------------------------------------
  // 1) Audio -> transcript + structured instructions
  // ---------------------------------------------------------------------
  Future<Map<String, dynamic>> extractFromAudio(
      File audio, {
        String languageHint = 'Auto-detect',
      }) async {
    if (!AppConfig.hasKey) {
      await Future.delayed(const Duration(seconds: 6));
      return DemoData.extraction;
    }
    final bytes = await audio.readAsBytes();
    if (bytes.length < 2000) {
      throw AiException('The recording was too short. Please record again.');
    }
    final prompt = '''
You are a careful medical scribe. The audio is a consultation between a healthcare professional and a patient. Speech may be Telugu, Hindi, English or a mix (spoken language hint: $languageHint).

$_safety
Return ONLY JSON with exactly these keys:
{
 "transcript": "verbatim transcript in the original spoken language/script, each turn on a new line prefixed 'Doctor:' or 'Patient:' when you can tell",
 "doctorName": string|null,
 "healthIssue": "what the doctor said the patient's problem is, in plain words (English)",
 "medicines": [{"name":string,"dose":string|null,"frequency":string|null,"timing":[string],"duration":string|null,"notes":string|null}],
 "tests": [string],
 "precautions": [string],
 "foodRestrictions": [string],
 "followUp": string|null,
 "warningSigns": [string],
 "otherInstructions": [string],
 "unclear": [string]
}
"timing" examples: "after breakfast", "after dinner", "at bedtime".
"unclear" = anything mentioned but inaudible or ambiguous that the patient should ask the doctor about.
All fields except transcript must be in simple English.
''';
    return _generate([
      {
        'inline_data': {
          'mime_type': 'audio/mp4',
          'data': base64Encode(bytes),
        }
      },
      {'text': prompt},
    ]);
  }

  Map<String, dynamic> demoExtraction() => DemoData.extraction;

  // ---------------------------------------------------------------------
  // 2) Option A - quiz from the recorded visit
  // ---------------------------------------------------------------------
  Future<List<QuizQuestion>> generateQuiz(VisitRecord v) async {
    if (!AppConfig.hasKey) {
      await Future.delayed(const Duration(seconds: 2));
      return DemoData.quiz;
    }
    final lang = langName(v.language);
    final prompt = '''
Create a short understanding quiz for a patient, based ONLY on this consultation.

CONSULTATION (structured): ${v.aiContext()}
TRANSCRIPT: ${v.transcript}

$_safety
Write 6 multiple-choice questions in $lang. Cover: the health issue, each medicine's timing/frequency/duration, food restrictions, tests, follow-up and warning signs (only those that exist).
Each question has exactly 4 options with plausible wrong answers (e.g. wrong timing or wrong number of days).
Return ONLY JSON:
{"questions":[{"question":string,"options":[string,string,string,string],"correctIndex":0-3,"doctorSaid":"the doctor's instruction this question is based on, in $lang"}]}
''';
    final j = await _generate([
      {'text': prompt}
    ], temperature: 0.4);
    final list = (j['questions'] as List? ?? [])
        .whereType<Map>()
        .map((m) => QuizQuestion.fromJson(Map<String, dynamic>.from(m)))
        .where((q) => q.options.length >= 2 && q.question.isNotEmpty)
        .toList();
    if (list.isEmpty) throw AiException('Could not build the quiz. Try again.');
    return list;
  }

  // ---------------------------------------------------------------------
  // 3) Option B - teach-back comparison (meaning, not wording)
  // ---------------------------------------------------------------------
  Future<TeachBackResult> compareTeachBack(
      VisitRecord v,
      String patientText,
      String language,
      ) async {
    if (!AppConfig.hasKey) {
      await Future.delayed(const Duration(seconds: 3));
      return DemoData.teachBack;
    }
    final prompt = '''
A patient was asked: "Tell me in your own words what you will do." Compare the patient's answer with what the healthcare professional actually instructed. Compare MEANING, not wording; the patient may answer in a different language than the instruction.

DOCTOR'S INSTRUCTIONS (structured): ${v.aiContext()}
DOCTOR'S TRANSCRIPT: ${v.transcript}
PATIENT'S ANSWER ($language): $patientText

$_safety
- Create one item per instruction (each medicine's timing/frequency/duration, tests, food rules, follow-up, warning signs, health issue) that exists above.
- status: "matched" (same meaning), "partial" (some right, some missing/different), "missed" (patient did not mention it), "conflict" (patient's answer differs from the instruction).
- "note": one neutral sentence in $language. For partial/missed/conflict say a possible difference was found and to re-confirm with the doctor or pharmacist. NEVER correct the instruction or suggest doses.
- "score" 0-100 = how much of the instructions the patient correctly understood.
- "summary": 1-2 neutral sentences in $language.
Return ONLY JSON:
{"score":int,"summary":string,"items":[{"topic":string,"doctorSaid":string,"patientSaid":string|null,"status":"matched|partial|missed|conflict","note":string}]}
''';
    final j = await _generate([
      {'text': prompt}
    ], temperature: 0.1);
    final r = TeachBackResult.fromJson(j);
    if (r.items.isEmpty) {
      throw AiException('Could not analyse the answer. Try again.');
    }
    return r;
  }

  // ---------------------------------------------------------------------
  // 4) Report analysis (image or PDF -> simple explanation)
  // ---------------------------------------------------------------------
  Future<ReportAnalysis> analyzeReport(
      File file, {
        String language = 'English',
      }) async {
    if (!AppConfig.hasKey) {
      await Future.delayed(const Duration(seconds: 3));
      return ReportAnalysis.demo;
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      throw AiException('This file is too large. Please use one under 10 MB.');
    }
    final path = file.path.toLowerCase();
    final mime = path.endsWith('.pdf')
        ? 'application/pdf'
        : path.endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';

    final prompt = '''
You are a careful medical-report explainer for a patient. The attached file is a medical report (lab test, scan report, discharge summary or similar). Explain it in simple $language that a person with no medical background can follow.

STRICT RULES:
- Use ONLY what is written in the report. Never invent values, units or ranges.
- Decide each status ONLY by comparing the value with the reference range printed on the report. If no range is printed, use "unknown".
- Do NOT diagnose. Never say the patient has or does not have a disease. You may explain in general terms what a high or low value of a test is commonly associated with, and always say that only a doctor can find the cause.
- Do NOT recommend medicines, doses, supplements or treatments. Never tell the patient to change any medicine.
- Never say the doctor or the lab is wrong.
- If part of the report is blurry or unreadable, put it under "unclear" instead of guessing.
- "urgency": "urgent" only if the report itself marks a value as critical/panic or a value is far outside its printed range; "soon" if any value is outside its printed range; otherwise "routine".
- If the file is not a medical report, return an empty "values" list and explain that in "summary".

Return ONLY JSON with exactly these keys:
{
 "reportType": string,
 "reportDate": string|null,
 "summary": "2-3 simple sentences on what the report shows overall",
 "values": [{"name":string,"value":string|null,"unit":string|null,"referenceRange":string|null,"status":"low|normal|high|critical|unknown","meaning":"1-2 simple sentences: what this test measures and what this result means in general"}],
 "attention": [string],
 "questionsForDoctor": [string],
 "nextSteps": [string],
 "urgency": "routine|soon|urgent",
 "urgencyReason": string|null,
 "unclear": [string]
}
"attention" = plain-words list of values outside the printed range.
"nextSteps" = only non-medical steps such as showing the report to the doctor or carrying the original report.
All text values must be in $language. Keep the status words and urgency words in English exactly as listed.
''';

    final j = await _generate([
      {
        'inline_data': {
          'mime_type': mime,
          'data': base64Encode(bytes),
        }
      },
      {'text': prompt},
    ], temperature: 0.2);
    final r = ReportAnalysis.fromJson(j);
    if (r.values.isEmpty && r.summary.isEmpty) {
      throw AiException(
          'Could not read this report. Please try a clearer photo.');
    }
    return r;
  }
}

/// Sample data so the UI can be tested without an API key.
class DemoData {
  static Map<String, dynamic> get extraction => {
    'transcript':
    'Doctor: Good morning. From your symptoms, this looks like a viral fever with a mild throat infection.\n'
        'Patient: Okay doctor, what should I take?\n'
        'Doctor: Take Paracetamol 500 mg after breakfast and after dinner for five days. Take Cetirizine 10 mg at bedtime for three days.\n'
        'Doctor: Avoid cold drinks and ice cream, and drink warm water. Get one blood test, CBC, tomorrow morning.\n'
        'Doctor: Come back for review after five days. If the fever goes above 102 or you feel breathless, come immediately.',
    'doctorName': 'Dr. Ramesh (sample data)',
    'healthIssue':
    'Viral fever with a mild throat infection, as explained by the doctor.',
    'medicines': [
      {
        'name': 'Paracetamol',
        'dose': '500 mg',
        'frequency': 'Twice daily',
        'timing': ['After breakfast', 'After dinner'],
        'duration': '5 days',
        'notes': null
      },
      {
        'name': 'Cetirizine',
        'dose': '10 mg',
        'frequency': 'Once daily',
        'timing': ['At bedtime'],
        'duration': '3 days',
        'notes': null
      }
    ],
    'tests': ['CBC blood test tomorrow morning'],
    'precautions': ['Drink warm water'],
    'foodRestrictions': ['Avoid cold drinks', 'Avoid ice cream'],
    'followUp': 'Review after 5 days',
    'warningSigns': ['Fever above 102', 'Feeling breathless'],
    'otherInstructions': [],
    'unclear': []
  };

  static List<QuizQuestion> get quiz => const [
    QuizQuestion(
      question: 'When should you take Paracetamol?',
      options: [
        'Only after dinner',
        'After breakfast and after dinner',
        'Before breakfast',
        'Only when fever comes'
      ],
      correctIndex: 1,
      doctorSaid: 'Paracetamol 500 mg after breakfast and after dinner.',
    ),
    QuizQuestion(
      question: 'For how many days should you take Paracetamol?',
      options: ['3 days', '7 days', '5 days', '10 days'],
      correctIndex: 2,
      doctorSaid: 'Take it for five days.',
    ),
    QuizQuestion(
      question: 'Which food items did the doctor ask you to avoid?',
      options: [
        'Spicy food',
        'Cold drinks and ice cream',
        'Milk',
        'Fruits'
      ],
      correctIndex: 1,
      doctorSaid: 'Avoid cold drinks and ice cream.',
    ),
    QuizQuestion(
      question: 'When should you come back for review?',
      options: [
        'After 2 days',
        'After 5 days',
        'After a month',
        'No review needed'
      ],
      correctIndex: 1,
      doctorSaid: 'Come back for review after five days.',
    ),
  ];

  static TeachBackResult get teachBack => const TeachBackResult(
    score: 62,
    summary:
    'Most instructions were understood. A possible difference was found in the medicine timing. Please re-confirm with your doctor or pharmacist.',
    items: [
      TeachBackItem(
        topic: 'Paracetamol timing',
        doctorSaid: 'After breakfast and after dinner',
        patientSaid: 'After dinner only',
        status: MatchStatus.partial,
        note:
        'A possible difference was found. Please re-confirm this with your doctor or pharmacist.',
      ),
      TeachBackItem(
        topic: 'Paracetamol duration',
        doctorSaid: '5 days',
        patientSaid: '5 days',
        status: MatchStatus.matched,
        note: 'Matches the instruction.',
      ),
      TeachBackItem(
        topic: 'Food to avoid',
        doctorSaid: 'Cold drinks and ice cream',
        patientSaid: 'Cold drinks',
        status: MatchStatus.partial,
        note:
        'Ice cream was not mentioned. Please re-confirm with your doctor.',
      ),
      TeachBackItem(
        topic: 'Follow-up',
        doctorSaid: 'Review after 5 days',
        patientSaid: null,
        status: MatchStatus.missed,
        note: 'Not mentioned. Please re-confirm the follow-up date.',
      ),
    ],
  );
}