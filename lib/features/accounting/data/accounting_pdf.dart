// The `pdf` package's `pw.SizedBox` and a few other widgets don't expose
// const constructors, so we opt out of `prefer_const_constructors` here.
// ignore_for_file: prefer_const_constructors

import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../profile/domain/artist.dart';
import '../domain/transaction.dart';

/// Builds the accounting export as a PDF byte stream.
///
/// The document is designed as a single continuous multi-page report:
/// - Studio header + report generation date
/// - Global summary (all-time revenue / expenses / balance)
/// - Current month summary
/// - Monthly breakdown (revenue vs. expenses)
/// - Category breakdown
/// - Payment methods breakdown
/// - Full paginated table of every transaction (most recent first)
Future<Uint8List> buildAccountingPdf({
  required Artist artist,
  required List<Transaction> transactions,
  required DateTime generatedAt,
}) async {
  final pw.Document doc = pw.Document(
    title: 'Comptabilité — ${artist.studioName}',
    author: artist.fullName,
    creator: 'DesK Tattoo',
    subject: 'Rapport comptable',
  );

  // Sort transactions most recent first.
  final List<Transaction> sorted = List<Transaction>.from(transactions)
    ..sort((Transaction a, Transaction b) => b.date.compareTo(a.date));

  final NumberFormat currency =
      NumberFormat.currency(locale: 'fr_FR', symbol: '€');
  final DateFormat dayLong = DateFormat('EEEE d MMMM y', 'fr_FR');
  final DateFormat dayShort = DateFormat('dd/MM/yyyy', 'fr_FR');
  final DateFormat monthYear = DateFormat('MMMM y', 'fr_FR');
  final DateFormat headerDate =
      DateFormat("EEEE d MMMM y 'à' HH:mm", 'fr_FR');

  // Aggregates.
  double totalIncome = 0;
  double totalExpense = 0;
  final Map<String, double> incomeByCategory = <String, double>{};
  final Map<String, double> expenseByCategory = <String, double>{};
  final Map<PaymentMethod, double> byMethod = <PaymentMethod, double>{};
  final Map<String, _MonthTotals> byMonth = <String, _MonthTotals>{};

  for (final Transaction t in sorted) {
    if (t.type == TransactionType.income) {
      totalIncome += t.amount;
      final String cat = t.category ?? 'Non classé';
      incomeByCategory[cat] = (incomeByCategory[cat] ?? 0) + t.amount;
    } else {
      totalExpense += t.amount;
      final String cat = t.category ?? 'Non classé';
      expenseByCategory[cat] = (expenseByCategory[cat] ?? 0) + t.amount;
    }
    byMethod[t.method] = (byMethod[t.method] ?? 0) + t.amount;
    final String key = DateFormat('yyyy-MM').format(t.date);
    final _MonthTotals m = byMonth.putIfAbsent(
      key,
      () => _MonthTotals(monthYear.format(t.date)),
    );
    if (t.type == TransactionType.income) {
      m.income += t.amount;
    } else {
      m.expense += t.amount;
    }
  }

  final double balance = totalIncome - totalExpense;

  // Current month totals.
  final DateTime now = generatedAt;
  final String currentMonthKey = DateFormat('yyyy-MM').format(now);
  final _MonthTotals currentMonth =
      byMonth[currentMonthKey] ?? _MonthTotals(monthYear.format(now));

  const PdfColor primary = PdfColor.fromInt(0xFF6750A4);
  const PdfColor income = PdfColor.fromInt(0xFF2E7D32);
  const PdfColor expense = PdfColor.fromInt(0xFFC62828);
  const PdfColor muted = PdfColor.fromInt(0xFF6B6B6B);
  const PdfColor surface = PdfColor.fromInt(0xFFF3F0F7);

  pw.Widget kpiCard(
    String label,
    String value, {
    required PdfColor color,
    String? subtitle,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor(
          color.red,
          color.green,
          color.blue,
          0.08,
        ),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: muted,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...<pw.Widget>[
            pw.SizedBox(height: 2),
            pw.Text(
              subtitle,
              style: pw.TextStyle(fontSize: 8, color: muted),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget sectionTitle(String label) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 8),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: primary,
        ),
      ),
    );
  }

  pw.Widget breakdownTable(Map<String, double> data, PdfColor color) {
    if (data.isEmpty) {
      return pw.Text(
        'Aucune donnée.',
        style: pw.TextStyle(fontSize: 10, color: muted),
      );
    }
    final List<MapEntry<String, double>> sortedEntries = data.entries.toList()
      ..sort(
        (MapEntry<String, double> a, MapEntry<String, double> b) =>
            b.value.compareTo(a.value),
      );
    final double sum =
        sortedEntries.fold<double>(0, (double s, MapEntry<String, double> e) => s + e.value);

    return pw.Table(
      columnWidths: const <int, pw.TableColumnWidth>{
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
      children: <pw.TableRow>[
        for (final MapEntry<String, double> entry in sortedEntries)
          pw.TableRow(
            children: <pw.Widget>[
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text(
                  entry.key,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text(
                  currency.format(entry.value),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 4),
                child: pw.Text(
                  sum == 0
                      ? '—'
                      : '${(entry.value / sum * 100).toStringAsFixed(1)}%',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(fontSize: 9, color: muted),
                ),
              ),
            ],
          ),
      ],
    );
  }

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
                'Comptabilité — ${artist.studioName}',
                style: pw.TextStyle(fontSize: 9, color: muted),
              ),
              pw.Text(
                headerDate.format(now),
                style: pw.TextStyle(fontSize: 9, color: muted),
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
              'DesK Tattoo · ${artist.fullName}',
              style: pw.TextStyle(fontSize: 8, color: muted),
            ),
            pw.Text(
              'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: muted),
            ),
          ],
        ),
      ),
      build: (pw.Context ctx) => <pw.Widget>[
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: surface,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  pw.Text(
                    'Rapport comptable',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    artist.studioName,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    artist.fullName,
                    style: pw.TextStyle(fontSize: 10, color: muted),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: <pw.Widget>[
                  pw.Text(
                    'Généré le',
                    style: pw.TextStyle(fontSize: 8, color: muted),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    headerDate.format(now),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '${sorted.length} transaction${sorted.length > 1 ? 's' : ''}',
                    style: pw.TextStyle(fontSize: 9, color: muted),
                  ),
                ],
              ),
            ],
          ),
        ),
        sectionTitle('Synthèse globale'),
        pw.Row(
          children: <pw.Widget>[
            pw.Expanded(
              child: kpiCard(
                'Revenus totaux',
                currency.format(totalIncome),
                color: income,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: kpiCard(
                'Dépenses totales',
                currency.format(totalExpense),
                color: expense,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: kpiCard(
                'Solde',
                currency.format(balance),
                color: balance >= 0 ? income : expense,
              ),
            ),
          ],
        ),
        sectionTitle('Mois en cours — ${monthYear.format(now)}'),
        pw.Row(
          children: <pw.Widget>[
            pw.Expanded(
              child: kpiCard(
                'Revenus',
                currency.format(currentMonth.income),
                color: income,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: kpiCard(
                'Dépenses',
                currency.format(currentMonth.expense),
                color: expense,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: kpiCard(
                'Solde du mois',
                currency.format(currentMonth.balance),
                color: currentMonth.balance >= 0 ? income : expense,
              ),
            ),
          ],
        ),
        sectionTitle('Répartition par mois'),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: primary),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: const <int, pw.Alignment>{
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
          headerAlignments: const <int, pw.Alignment>{
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
          headers: const <String>['Mois', 'Revenus', 'Dépenses', 'Solde'],
          data: <List<String>>[
            for (final MapEntry<String, _MonthTotals> e in _sortedMonths(
              byMonth,
            ))
              <String>[
                _capitalize(e.value.label),
                currency.format(e.value.income),
                currency.format(e.value.expense),
                currency.format(e.value.balance),
              ],
          ],
        ),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: <pw.Widget>[
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  sectionTitle('Revenus par catégorie'),
                  breakdownTable(incomeByCategory, income),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: <pw.Widget>[
                  sectionTitle('Dépenses par catégorie'),
                  breakdownTable(expenseByCategory, expense),
                ],
              ),
            ),
          ],
        ),
        sectionTitle('Méthodes de paiement'),
        breakdownTable(
          <String, double>{
            for (final MapEntry<PaymentMethod, double> e in byMethod.entries)
              e.key.label: e.value,
          },
          primary,
        ),
        sectionTitle('Détail des transactions (${sorted.length})'),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(color: primary),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellHeight: 22,
          columnWidths: const <int, pw.TableColumnWidth>{
            0: pw.FixedColumnWidth(60),
            1: pw.FlexColumnWidth(3),
            2: pw.FlexColumnWidth(2),
            3: pw.FlexColumnWidth(1.5),
            4: pw.FlexColumnWidth(1.5),
            5: pw.FixedColumnWidth(70),
          },
          cellAlignments: const <int, pw.Alignment>{
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerLeft,
            4: pw.Alignment.centerLeft,
            5: pw.Alignment.centerRight,
          },
          headerAlignments: const <int, pw.Alignment>{
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.centerLeft,
            3: pw.Alignment.centerLeft,
            4: pw.Alignment.centerLeft,
            5: pw.Alignment.centerRight,
          },
          headers: const <String>[
            'Date',
            'Libellé',
            'Client',
            'Catégorie',
            'Paiement',
            'Montant',
          ],
          data: <List<String>>[
            for (final Transaction t in sorted)
              <String>[
                dayShort.format(t.date),
                t.label,
                t.clientName ?? '—',
                t.category ?? '—',
                t.method.label,
                '${t.type == TransactionType.income ? '+' : '-'}${currency.format(t.amount)}',
              ],
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: surface,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text(
                'Total ${sorted.length} transactions · Rapport arrêté le ${dayLong.format(now)}',
                style: pw.TextStyle(fontSize: 9, color: muted),
              ),
              pw.Text(
                'Solde : ${currency.format(balance)}',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: balance >= 0 ? income : expense,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  return doc.save();
}

class _MonthTotals {
  _MonthTotals(this.label);

  final String label;
  double income = 0;
  double expense = 0;

  double get balance => income - expense;
}

List<MapEntry<String, _MonthTotals>> _sortedMonths(
  Map<String, _MonthTotals> byMonth,
) {
  final List<MapEntry<String, _MonthTotals>> entries = byMonth.entries.toList()
    ..sort(
      (MapEntry<String, _MonthTotals> a, MapEntry<String, _MonthTotals> b) =>
          b.key.compareTo(a.key),
    );
  return entries;
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
