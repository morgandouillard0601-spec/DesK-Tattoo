// Le package `pdf` n'expose pas de constructeurs const sur `pw.SizedBox` et
// quelques autres widgets, on désactive donc la règle sur ce fichier.
// ignore_for_file: prefer_const_constructors

import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/consent_text.dart';
import '../domain/intake_submission.dart';

const PdfColor _primary = PdfColor.fromInt(0xFF5E1B89);
const PdfColor _muted = PdfColor.fromInt(0xFF6B6B6B);
const PdfColor _surface = PdfColor.fromInt(0xFFF3F0F7);

/// Construit le contrat signé remis au client et archivé par le studio.
Future<Uint8List> buildConsentPdf({
  required IntakeStudio studio,
  required IntakeSubmission submission,
  required Uint8List signaturePng,
  required DateTime signedAt,
}) async {
  final pw.Document doc = pw.Document(
    title: 'Consentement — ${submission.fullName}',
    author: studio.displayName,
    creator: 'DesK Tattoo',
    subject: ConsentText.title,
  );

  final DateFormat dayShort = DateFormat('dd/MM/yyyy', 'fr_FR');
  final DateFormat signedFormat =
      DateFormat("d MMMM y 'à' HH:mm", 'fr_FR');
  final pw.MemoryImage signature = pw.MemoryImage(signaturePng);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
      header: (pw.Context ctx) {
        if (ctx.pageNumber == 1) return pw.SizedBox();
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text(
                '${ConsentText.title} — ${studio.displayName}',
                style: pw.TextStyle(fontSize: 9, color: _muted),
              ),
              pw.Text(
                submission.fullName,
                style: pw.TextStyle(fontSize: 9, color: _muted),
              ),
            ],
          ),
        );
      },
      footer: (pw.Context ctx) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Text(
              'DesK Tattoo · ${studio.displayName}',
              style: pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ),
      build: (pw.Context ctx) => <pw.Widget>[
        _header(studio, submission, signedAt, signedFormat),
        _sectionTitle('Informations du client'),
        _infoTable(<List<String>>[
          <String>['Nom et prénom', submission.fullName],
          <String>[
            'Date de naissance',
            '${dayShort.format(submission.birthDate)} '
                '(${ageOn(submission.birthDate, signedAt)} ans)',
          ],
          <String>['Téléphone', submission.phone.isEmpty ? '—' : submission.phone],
          <String>['Email', submission.email.isEmpty ? '—' : submission.email],
          <String>[
            'Adresse',
            _addressLine(submission),
          ],
        ]),
        _sectionTitle('Déclaration de santé'),
        _infoTable(<List<String>>[
          for (final HealthQuestion q in ConsentText.healthQuestions)
            <String>[
              q.label,
              (submission.healthAnswers[q.key] ?? '').trim().isEmpty
                  ? 'Non renseigné'
                  : submission.healthAnswers[q.key]!.trim(),
            ],
        ]),
        _sectionTitle('Clauses du contrat'),
        for (final ConsentClause clause in ConsentText.clauses)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  clause.title,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  clause.body,
                  style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.4),
                ),
              ],
            ),
          ),
        _sectionTitle('Consentements recueillis'),
        for (final ConsentCheckbox box in ConsentText.checkboxes)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Container(
                  width: 12,
                  height: 12,
                  margin: const pw.EdgeInsets.only(top: 1, right: 6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _primary, width: 1),
                    borderRadius: pw.BorderRadius.circular(2),
                    color: submission.accepted(box.key) ? _primary : null,
                  ),
                  child: submission.accepted(box.key)
                      ? pw.Center(
                          child: pw.Text(
                            'X',
                            style: pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                pw.Expanded(
                  child: pw.Text(
                    box.required ? '${box.label} (obligatoire)' : box.label,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        pw.SizedBox(height: 16),
        _signatureBlock(studio, submission, signature, signedAt, signedFormat),
      ],
    ),
  );

  return doc.save();
}

String _addressLine(IntakeSubmission submission) {
  final List<String> parts = <String>[
    if (submission.address.trim().isNotEmpty) submission.address.trim(),
    if (submission.postalCode.trim().isNotEmpty) submission.postalCode.trim(),
    if (submission.city.trim().isNotEmpty) submission.city.trim(),
  ];
  return parts.isEmpty ? '—' : parts.join(' · ');
}

pw.Widget _header(
  IntakeStudio studio,
  IntakeSubmission submission,
  DateTime signedAt,
  DateFormat signedFormat,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(16),
    decoration: pw.BoxDecoration(
      color: _surface,
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: <pw.Widget>[
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: <pw.Widget>[
                pw.Text(
                  ConsentText.title,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _primary,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  studio.displayName,
                  style: const pw.TextStyle(fontSize: 12),
                ),
                if (studio.city.trim().isNotEmpty)
                  pw.Text(
                    studio.city,
                    style: pw.TextStyle(fontSize: 10, color: _muted),
                  ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: <pw.Widget>[
                pw.Text(
                  'Signé le',
                  style: pw.TextStyle(fontSize: 8, color: _muted),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  signedFormat.format(signedAt),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          ConsentText.intro,
          style: const pw.TextStyle(fontSize: 9, lineSpacing: 1.4),
        ),
      ],
    ),
  );
}

pw.Widget _signatureBlock(
  IntakeStudio studio,
  IntakeSubmission submission,
  pw.MemoryImage signature,
  DateTime signedAt,
  DateFormat signedFormat,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _primary, width: 1),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          'Signature du client',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _primary,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          ConsentText.signatureNotice,
          style: const pw.TextStyle(fontSize: 8, lineSpacing: 1.3),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(
                    submission.fullName,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    signedFormat.format(signedAt),
                    style: pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                ],
              ),
            ),
            pw.Container(
              width: 200,
              height: 80,
              alignment: pw.Alignment.bottomRight,
              child: pw.Image(signature, fit: pw.BoxFit.contain),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _sectionTitle(String label) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
    child: pw.Text(
      label,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: _primary,
      ),
    ),
  );
}

pw.Widget _infoTable(List<List<String>> rows) {
  return pw.Table(
    columnWidths: const <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2),
      1: pw.FlexColumnWidth(3),
    },
    children: <pw.TableRow>[
      for (final List<String> row in rows)
        pw.TableRow(
          children: <pw.Widget>[
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                row[0],
                style: pw.TextStyle(fontSize: 9, color: _muted),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                row[1],
                style: const pw.TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
    ],
  );
}
