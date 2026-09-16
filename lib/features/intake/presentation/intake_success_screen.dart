import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Confirmation affichée au client après signature du contrat.
class IntakeSuccessScreen extends StatelessWidget {
  const IntakeSuccessScreen({
    required this.studioName,
    required this.clientName,
    this.pdfBytes,
    super.key,
  });

  final String studioName;
  final String clientName;
  final Uint8List? pdfBytes;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Uint8List? pdf = pdfBytes;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              theme.colorScheme.surface,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 44,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Merci $clientName',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ta fiche et ton contrat signé ont été transmis à '
                      '$studioName. Le studio les retrouve directement dans '
                      'ton dossier client.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 26),
                    if (pdf != null) ...<Widget>[
                      FilledButton.icon(
                        onPressed: () => Printing.layoutPdf(
                          onLayout: (_) async => pdf,
                          name: 'contrat-$clientName.pdf',
                        ),
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('Voir mon contrat'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => Printing.sharePdf(
                          bytes: pdf,
                          filename: 'contrat-$clientName.pdf',
                        ),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Garder une copie'),
                      ),
                    ] else
                      Text(
                        'Le studio peut te remettre une copie du contrat sur '
                        'demande.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
