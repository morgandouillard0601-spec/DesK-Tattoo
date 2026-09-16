import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../../shared/utils/date_format.dart';
import '../../../shared/utils/paris_clock.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../profile/data/artist_repository.dart';
import '../../profile/domain/artist.dart';
import '../data/accounting_export_service.dart';
import '../data/accounting_pdf.dart';
import '../data/accounting_repository.dart';
import '../domain/transaction.dart';
import 'transaction_form_sheet.dart';

const AccountingExportService _exportService = AccountingExportService();

class AccountingScreen extends ConsumerWidget {
  const AccountingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<List<Transaction>> accountingAsync =
        ref.watch(accountingProvider);
    final AccountingNotifier notifier =
        ref.read(accountingProvider.notifier);

    if (accountingAsync.isLoading && !accountingAsync.hasValue) {
      return Scaffold(
        appBar: AppBar(title: const Text('Comptabilité')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final DateTime now = DateTime.now();
    final double income = notifier.monthIncome(now);
    final double expense = notifier.monthExpense(now);
    final double balance = income - expense;
    final List<Transaction> transactions = notifier.sorted();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comptabilité'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Aperçu PDF',
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () => _previewPdf(context, ref),
          ),
          IconButton(
            tooltip: 'Télécharger',
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _downloadPdf(context, ref),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _BalanceCard(
                month: AppDateFormat.monthYear(now),
                balance: balance,
                income: income,
                expense: expense,
                onPreview: () => _previewPdf(context, ref),
                onDownload: () => _downloadPdf(context, ref),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: <Widget>[
                  Text(
                    'Transactions récentes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${transactions.length}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (transactions.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.receipt_long_rounded,
                title: 'Aucune transaction',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList.separated(
                itemCount: transactions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) =>
                    _TransactionTile(tx: transactions[index]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final Transaction? created =
              await showTransactionFormSheet(context);
          if (context.mounted && created != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Transaction ajoutée · ${created.label}')),
            );
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Transaction'),
      ),
    );
  }

  Future<void> _previewPdf(BuildContext context, WidgetRef ref) async {
    final List<Transaction> transactions =
        ref.read(accountingProvider.notifier).sorted();
    final Artist artist = ref.read(artistProvider);

    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune transaction à exporter')),
      );
      return;
    }

    final DateTime now = ParisClock.now();
    final String filename =
        'compta_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.pdf';

    await Printing.layoutPdf(
      name: filename,
      format: PdfPageFormat.a4,
      onLayout: (PdfPageFormat format) async {
        final Uint8List bytes = await buildAccountingPdf(
          artist: artist,
          transactions: transactions,
          generatedAt: now,
        );
        return bytes;
      },
    );
  }

  Future<void> _downloadPdf(BuildContext context, WidgetRef ref) async {
    final List<Transaction> transactions =
        ref.read(accountingProvider.notifier).sorted();
    final Artist artist = ref.read(artistProvider);

    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune transaction à télécharger')),
      );
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Row(
          children: <Widget>[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Génération du PDF…'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final AccountingPdfResult result = await _exportService.downloadPdf(
        artist: artist,
        transactions: transactions,
        generatedAt: ParisClock.now(),
      );

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            'Téléchargé · ${result.filename}\n'
            'Fichiers → « Sur mon iPad » → DesK Tattoo → exports',
          ),
          action: SnackBarAction(
            label: 'Partager',
            onPressed: () {
              _exportService.shareBytes(result.bytes, result.filename);
            },
          ),
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur d\'export : $e')),
      );
    }
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.month,
    required this.balance,
    required this.income,
    required this.expense,
    required this.onPreview,
    required this.onDownload,
  });

  final String month;
  final double balance;
  final double income;
  final double expense;
  final VoidCallback onPreview;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    // Deep gradient using primary shades for a bold, high-contrast card.
    final List<Color> gradient = theme.brightness == Brightness.light
        ? <Color>[cs.primary, cs.tertiary]
        : <Color>[cs.primaryContainer, cs.tertiaryContainer];
    final Color onGradient = theme.brightness == Brightness.light
        ? cs.onPrimary
        : cs.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Solde de $month'.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: onGradient,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppDateFormat.currencyEur(balance),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: onGradient,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Expanded(
                child: _MoneyMini(
                  icon: Icons.trending_up_rounded,
                  label: 'Revenus',
                  amount: income,
                  accent: const Color(0xFF34C759),
                  onColor: onGradient,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MoneyMini(
                  icon: Icons.trending_down_rounded,
                  label: 'Dépenses',
                  amount: expense,
                  accent: const Color(0xFFFF453A),
                  onColor: onGradient,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Aperçu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onGradient,
                    side: BorderSide(color: onGradient, width: 1.5),
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Télécharger'),
                  style: FilledButton.styleFrom(
                    backgroundColor: onGradient,
                    foregroundColor: cs.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoneyMini extends StatelessWidget {
  const _MoneyMini({
    required this.icon,
    required this.label,
    required this.amount,
    required this.accent,
    required this.onColor,
  });

  final IconData icon;
  final String label;
  final double amount;
  final Color accent;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 16,
            backgroundColor: accent,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: onColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  AppDateFormat.currencyEur(amount),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: onColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isIncome = tx.type == TransactionType.income;
    final Color color =
        isIncome ? Colors.green.shade700 : theme.colorScheme.error;

    return Card(
      color: theme.colorScheme.surfaceContainerHigh,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(tx.method.icon, color: color),
        ),
        title: Text(
          tx.label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          <String?>[
            tx.clientName,
            tx.category,
            AppDateFormat.relativeDay(tx.date),
          ].whereType<String>().join(' · '),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${AppDateFormat.currencyEur(tx.amount)}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
