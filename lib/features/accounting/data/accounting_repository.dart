import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/artist_scoped_notifier.dart';
import '../domain/transaction.dart';

class AccountingNotifier extends ArtistScopedNotifier<Transaction> {
  @override
  String get table => 'transactions';

  @override
  String get orderColumn => 'date';

  @override
  bool get orderAscending => false;

  @override
  Transaction fromRow(Map<String, dynamic> row) =>
      Transaction.fromSupabase(row);

  List<Transaction> sorted() {
    final List<Transaction> list = List<Transaction>.from(items)
      ..sort((Transaction a, Transaction b) => b.date.compareTo(a.date));
    return list;
  }

  double monthIncome(DateTime month) => items
      .where(
        (Transaction t) =>
            t.type == TransactionType.income &&
            t.date.year == month.year &&
            t.date.month == month.month,
      )
      .fold<double>(0, (double sum, Transaction t) => sum + t.amount);

  double monthExpense(DateTime month) => items
      .where(
        (Transaction t) =>
            t.type == TransactionType.expense &&
            t.date.year == month.year &&
            t.date.month == month.month,
      )
      .fold<double>(0, (double sum, Transaction t) => sum + t.amount);

  Future<void> add(Transaction tx) => insertRow(tx.toSupabase());

  /// Nommée `save` et non `update` : `AsyncNotifier` expose déjà `update`.
  Future<void> save(Transaction tx) => updateRow(tx.id, tx.toSupabase());

  Future<void> delete(String id) => deleteRow(id);
}

final AsyncNotifierProvider<AccountingNotifier, List<Transaction>>
    accountingProvider =
    AsyncNotifierProvider<AccountingNotifier, List<Transaction>>(
  AccountingNotifier.new,
);
