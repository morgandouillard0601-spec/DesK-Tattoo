import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../profile/domain/artist.dart';
import '../domain/transaction.dart';
import 'accounting_pdf.dart';

class AccountingPdfResult {
  const AccountingPdfResult({
    required this.bytes,
    required this.filename,
    required this.file,
  });

  final Uint8List bytes;
  final String filename;
  final File file;
}

class AccountingExportService {
  const AccountingExportService();

  /// Generates the accounting PDF and writes it to the app's Documents
  /// directory under `exports/`. The Documents directory is exposed to the
  /// iOS Files app via `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace`
  /// so the exported file is accessible from Fichiers → "Sur mon iPad" → DesK Tattoo.
  Future<AccountingPdfResult> downloadPdf({
    required Artist artist,
    required List<Transaction> transactions,
    required DateTime generatedAt,
  }) async {
    final Uint8List bytes = await buildAccountingPdf(
      artist: artist,
      transactions: transactions,
      generatedAt: generatedAt,
    );

    final Directory docsDir = await getApplicationDocumentsDirectory();
    final Directory exportsDir =
        Directory('${docsDir.path}/exports');
    if (!exportsDir.existsSync()) {
      await exportsDir.create(recursive: true);
    }

    final String filename = _buildFilename(generatedAt);
    final File file = File('${exportsDir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    return AccountingPdfResult(
      bytes: bytes,
      filename: filename,
      file: file,
    );
  }

  /// Opens the native iOS share sheet with the PDF as attachment.
  Future<void> shareBytes(Uint8List bytes, String filename) {
    return Printing.sharePdf(bytes: bytes, filename: filename);
  }

  String _buildFilename(DateTime date) {
    final String y = date.year.toString();
    final String m = date.month.toString().padLeft(2, '0');
    final String d = date.day.toString().padLeft(2, '0');
    return 'compta_$y$m$d.pdf';
  }
}
