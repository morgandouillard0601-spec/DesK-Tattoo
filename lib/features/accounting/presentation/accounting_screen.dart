import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/date_format.dart';
import '../../../shared/widgets/empty_state.dart';
import '../data/accounting_repository.dart';
import '../domain/transaction.dart';
import 'transaction_form_sheet.dart';

class AccountingScreen extends ConsumerWidget {
  const AccountingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    ref.watch(accountingProvider);
    final AccountingNotifier notifier =
        ref.read(accountingProvider.notifier);

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
            tooltip: 'Exporter',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export — bientôt')),
              );
            },
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
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.month,
    required this.balance,
    required this.income,
    required this.expense,
  });

  final String month;
  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[cs.primaryContainer, cs.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Solde de $month',
            style: theme.textTheme.labelLarge?.copyWith(
              color: cs.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppDateFormat.currencyEur(balance),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: cs.onPrimaryContainer,
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
                  color: Colors.green.shade700,
                  onColor: cs.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MoneyMini(
                  icon: Icons.trending_down_rounded,
                  label: 'Dépenses',
                  amount: expense,
                  color: Colors.red.shade700,
                  onColor: cs.onPrimaryContainer,
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
    required this.color,
    required this.onColor,
  });

  final IconData icon;
  final String label;
  final double amount;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 16,
            backgroundColor: color,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(color: onColor),
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
