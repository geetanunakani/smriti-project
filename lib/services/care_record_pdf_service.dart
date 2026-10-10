import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/visit_record.dart';

class CareRecordPdfService {
  static Future<File> generateCareRecord({
    required VisitRecord visit,
    required TeachBackResult teachBackResult,
  }) async {
    final pdf = pw.Document();

    final doctorName = _safeString(visit.doctorName);
    final healthIssue = _safeString(visit.healthIssue);
    final language = _safeString(visit.language);

    final date = _formatDate(visit.date);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),

        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SMRITI',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'SMRITI Care Record',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                'From what is heard — to what is remembered.',
                style: const pw.TextStyle(
                  fontSize: 10,
                ),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
            ],
          );
        },

        footer: (context) {
          return pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'SMRITI Care Record • Page ${context.pageNumber}',
              style: const pw.TextStyle(
                fontSize: 8,
              ),
            ),
          );
        },

        build: (context) {
          return [
            // ------------------------------------------------------------
            // 1. CONSULTATION SUMMARY
            // ------------------------------------------------------------

            _sectionTitle('1. Consultation Summary'),

            _infoRow(
              'Visit number',
              visit.visitNumber.toString(),
            ),

            _infoRow(
              'Date',
              date,
            ),

            _infoRow(
              'Healthcare professional',
              doctorName,
            ),

            _infoRow(
              'Health issue',
              healthIssue,
            ),

            _infoRow(
              'Language',
              language,
            ),

            pw.SizedBox(height: 18),

            // ------------------------------------------------------------
            // 2. ORIGINAL CONSULTATION
            // ------------------------------------------------------------

            _sectionTitle('2. Original Consultation'),

            _bodyText(
              visit.transcript.trim().isEmpty
                  ? 'No transcript available.'
                  : visit.transcript,
            ),

            pw.SizedBox(height: 18),

            // ------------------------------------------------------------
            // 3. PATIENT UNDERSTANDING
            // ------------------------------------------------------------

            _sectionTitle('3. Patient Understanding / Teach-Back'),

            _infoRow(
              'Understanding score',
              '${teachBackResult.score}/100',
            ),

            pw.SizedBox(height: 8),

            _bodyText(
              teachBackResult.summary.trim().isEmpty
                  ? 'No summary available.'
                  : teachBackResult.summary,
            ),

            pw.SizedBox(height: 12),

            if (teachBackResult.items.isNotEmpty)
              ...teachBackResult.items.map(
                    (item) => _teachBackItem(item),
              ),

            pw.SizedBox(height: 18),

            // ------------------------------------------------------------
            // 4. UNDERSTANDING VERIFICATION
            // ------------------------------------------------------------

            _sectionTitle('4. Understanding Verification'),

            _verificationSummary(teachBackResult),

            pw.SizedBox(height: 18),

            // ------------------------------------------------------------
            // 5. MEDICINES
            // ------------------------------------------------------------

            _sectionTitle('5. Medicines'),

            if (visit.medicines.isEmpty)
              _bodyText('No medicines were recorded.')
            else
              ...visit.medicines.map(
                    (medicine) => _medicineCard(medicine),
              ),

            pw.SizedBox(height: 18),

            // ------------------------------------------------------------
            // 6. TESTS
            // ------------------------------------------------------------

            _sectionTitle('6. Tests'),

            if (visit.tests.isEmpty)
              _bodyText('No tests were recorded.')
            else
              _bulletList(visit.tests),

            pw.SizedBox(height: 18),

            // ------------------------------------------------------------
            // 7. PRECAUTIONS
            // ------------------------------------------------------------

            _sectionTitle('7. Precautions'),

            if (visit.precautions.isEmpty)
              _bodyText('No precautions were recorded.')
            else
              _bulletList(visit.precautions),

            pw.SizedBox(height: 18),

            // ------------------------------------------------------------
            // 8. FOOD RESTRICTIONS
            // ------------------------------------------------------------

            _sectionTitle('8. Food Restrictions'),

            if (visit.foodRestrictions.isEmpty)
              _bodyText('No food restrictions were recorded.')
            else
              _bulletList(visit.foodRestrictions),

            pw.SizedBox(height: 18),

            // ------------------------------------------------------------
            // 9. WARNING SIGNS
            // ------------------------------------------------------------

            _sectionTitle('9. Warning Signs'),

            if (visit.warningSigns.isEmpty)
              _bodyText('No warning signs were recorded.')
            else
              _bulletList(visit.warningSigns),

            pw.SizedBox(height: 18),

            // ------------------------------------------------------------
            // 10. FOLLOW-UP
            // ------------------------------------------------------------

            _sectionTitle('10. Follow-Up'),

            _bodyText(
              _safeString(visit.followUp).isEmpty
                  ? 'No follow-up information was recorded.'
                  : _safeString(visit.followUp),
            ),

            pw.SizedBox(height: 18),

            // ------------------------------------------------------------
            // 11. OTHER INSTRUCTIONS
            // ------------------------------------------------------------

            _sectionTitle('11. Other Instructions'),

            if (visit.otherInstructions.isEmpty)
              _bodyText('No other instructions were recorded.')
            else
              _bulletList(visit.otherInstructions),

            pw.SizedBox(height: 24),

            // ------------------------------------------------------------
            // 12. SAFETY NOTE
            // ------------------------------------------------------------

            _sectionTitle('12. Safety Note'),

            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColors.grey500,
                ),
                borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(6),
                ),
              ),
              child: _bodyText(
                'This record reflects information captured from the '
                    'consultation and the patient teach-back. SMRITI does '
                    'not diagnose conditions, prescribe medicines, change '
                    'dosages, or replace a healthcare professional. '
                    'Possible differences in understanding should be '
                    're-confirmed with the doctor or pharmacist.',
              ),
            ),
          ];
        },
      ),
    );

    // ------------------------------------------------------------
    // SAVE PDF
    // ------------------------------------------------------------

    final directory = await getApplicationDocumentsDirectory();

    final safeDoctorName = _sanitizeFileName(
      doctorName.isEmpty ? 'Unknown' : doctorName,
    );

    final fileName =
        'Visit${visit.visitNumber}_${_fileDate(visit.date)}_Dr-$safeDoctorName.pdf';

    final file = File(
      '${directory.path}${Platform.pathSeparator}$fileName',
    );

    await file.writeAsBytes(
      await pdf.save(),
      flush: true,
    );

    return file;
  }

  // ------------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------------

  static String _safeString(String? value) {
    if (value == null) {
      return '';
    }

    return value.trim();
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _infoRow(
      String label,
      String? value,
      ) {
    final safeValue = _safeString(value);

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              safeValue.isEmpty ? 'Not provided' : safeValue,
              style: const pw.TextStyle(
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _bodyText(String text) {
    return pw.Text(
      text,
      style: const pw.TextStyle(
        fontSize: 10,
        lineSpacing: 2,
      ),
    );
  }

  static pw.Widget _bulletList(
      List<String> items,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: items
          .where(
            (item) => item.trim().isNotEmpty,
      )
          .map(
            (item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '• ',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Expanded(
                child: _bodyText(item),
              ),
            ],
          ),
        ),
      )
          .toList(),
    );
  }

  static pw.Widget _medicineCard(
      Medicine medicine,
      ) {
    final name = _safeString(medicine.name);
    final dose = _safeString(medicine.dose);
    final frequency = _safeString(medicine.frequency);
    final duration = _safeString(medicine.duration);

    // notes is a nullable String in the current Medicine model.
    final notes = _safeString(medicine.notes);

    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey400,
        ),
        borderRadius: const pw.BorderRadius.all(
          pw.Radius.circular(6),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            name.isEmpty ? 'Medicine' : name,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 6),

          if (dose.isNotEmpty)
            _infoRow('Dose', dose),

          if (frequency.isNotEmpty)
            _infoRow('Frequency', frequency),

          // timing is List<String>.
          if (medicine.timing.isNotEmpty)
            _infoRow(
              'Timing',
              medicine.timing.join(', '),
            ),

          if (duration.isNotEmpty)
            _infoRow('Duration', duration),

          // notes is String?, so display it as normal text.
          if (notes.isNotEmpty) ...[
            pw.SizedBox(height: 5),

            pw.Text(
              'Notes',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 4),

            _bodyText(notes),
          ],
        ],
      ),
    );
  }

  static pw.Widget _teachBackItem(
      TeachBackItem item,
      ) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey400,
        ),
        borderRadius: const pw.BorderRadius.all(
          pw.Radius.circular(6),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.topic,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 5),

          _infoRow(
            'Status',
            _statusText(item.status),
          ),

          _infoRow(
            'Healthcare professional said',
            item.doctorSaid,
          ),

          _infoRow(
            'Patient said',
            item.patientSaid,
          ),

          if (item.note.trim().isNotEmpty)
            _infoRow(
              'Note',
              item.note,
            ),
        ],
      ),
    );
  }

  static pw.Widget _verificationSummary(
      TeachBackResult result,
      ) {
    final mismatchCount = result.items
        .where(
          (item) => item.needsReconfirm,
    )
        .length;

    final matchedCount = result.items
        .where(
          (item) => !item.needsReconfirm,
    )
        .length;

    final text = mismatchCount == 0
        ? 'All recorded instructions were matched in the patient teach-back.'
        : '$matchedCount instruction(s) matched. '
        '$mismatchCount possible difference(s) require '
        'human re-confirmation with the healthcare professional '
        'or pharmacist.';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey500,
        ),
        borderRadius: const pw.BorderRadius.all(
          pw.Radius.circular(6),
        ),
      ),
      child: _bodyText(text),
    );
  }

  static String _statusText(
      MatchStatus status,
      ) {
    switch (status) {
      case MatchStatus.matched:
        return 'Matched';

      case MatchStatus.partial:
        return 'Possible difference';

      case MatchStatus.missed:
        return 'Not mentioned';

      case MatchStatus.conflict:
        return 'Possible conflict';
    }
  }

  static String _formatDate(
      DateTime date,
      ) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _fileDate(
      DateTime date,
      ) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = date.day.toString().padLeft(2, '0');

    return '$day-${months[date.month - 1]}-${date.year}';
  }

  static String _sanitizeFileName(
      String name,
      ) {
    final cleaned = name
        .replaceAll(
      RegExp(r'[<>:"/\\|?*]'),
      '',
    )
        .trim();

    if (cleaned.isEmpty) {
      return 'Unknown';
    }

    return cleaned.replaceAll(
      RegExp(r'\s+'),
      '-',
    );
  }
}