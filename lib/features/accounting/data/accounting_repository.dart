import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/transaction.dart';

class AccountingNotifier extends Notifier<List<Transaction>> {
  @override
  List<Transaction> build() => List<Transaction>.from(_seed);

  static DateTime _daysAgo(int days) =>
      DateTime.now().subtract(Duration(days: days));

  static final List<Transaction> _seed = <Transaction>[
    Transaction(
      id: 't1',
      type: TransactionType.income,
      label: 'Session sleeve 3/6',
      amount: 420,
      date: _daysAgo(1),
      method: PaymentMethod.card,
      clientName: 'Inès Garcia',
      category: 'Tatouage',
    ),
    Transaction(
      id: 't2',
      type: TransactionType.income,
      label: 'Lettrage avant-bras',
      amount: 280,
      date: _daysAgo(2),
      method: PaymentMethod.cash,
      clientName: 'Lucas Bernard',
      category: 'Tatouage',
    ),
    Transaction(
      id: 't3',
      type: TransactionType.expense,
      label: 'Commande cartouches',
      amount: 94.50,
      date: _daysAgo(3),
      method: PaymentMethod.card,
      category: 'Fournitures',
    ),
    Transaction(
      id: 't4',
      type: TransactionType.income,
      label: 'Acompte Hugo Petit',
      amount: 80,
      date: _daysAgo(4),
      method: PaymentMethod.deposit,
      clientName: 'Hugo Petit',
      category: 'Acompte',
    ),
    Transaction(
      id: 't5',
      type: TransactionType.income,
      label: 'Retouche rose',
      amount: 150,
      date: _daysAgo(5),
      method: PaymentMethod.card,
      clientName: 'Camille Moreau',
      category: 'Tatouage',
    ),
    Transaction(
      id: 't6',
      type: TransactionType.expense,
      label: 'Loyer atelier',
      amount: 850,
      date: _daysAgo(7),
      method: PaymentMethod.transfer,
      category: 'Loyer',
    ),
    Transaction(
      id: 't7',
      type: TransactionType.income,
      label: 'Mini tatouage poignet',
      amount: 90,
      date: _daysAgo(8),
      method: PaymentMethod.cash,
      clientName: 'Sofia Martins',
      category: 'Tatouage',
    ),
    Transaction(
      id: 't8',
      type: TransactionType.expense,
      label: 'Encres World Famous',
      amount: 78.40,
      date: _daysAgo(12),
      method: PaymentMethod.card,
      category: 'Fournitures',
    ),
    Transaction(
      id: 't9',
      type: TransactionType.income,
      label: 'Black work mollet',
      amount: 350,
      date: _daysAgo(14),
      method: PaymentMethod.card,
      clientName: 'Mathis Lefevre',
      category: 'Tatouage',
    ),
    Transaction(
      id: 't10',
      type: TransactionType.expense,
      label: 'Assurance pro',
      amount: 65,
      date: _daysAgo(20),
      method: PaymentMethod.transfer,
      category: 'Assurance',
    ),
  ];

  List<Transaction> sorted() {
    final List<Transaction> list = List<Transaction>.from(state)
      ..sort((Transaction a, Transaction b) => b.date.compareTo(a.date));
    return list;
  }

  double monthIncome(DateTime month) => state
      .where(
        (Transaction t) =>
            t.type == TransactionType.income &&
            t.date.year == month.year &&
            t.date.month == month.month,
      )
      .fold<double>(0, (double sum, Transaction t) => sum + t.amount);

  double monthExpense(DateTime month) => state
      .where(
        (Transaction t) =>
            t.type == TransactionType.expense &&
            t.date.year == month.year &&
            t.date.month == month.month,
      )
      .fold<double>(0, (double sum, Transaction t) => sum + t.amount);

  void add(Transaction tx) {
    state = <Transaction>[...state, tx];
  }
}

final NotifierProvider<AccountingNotifier, List<Transaction>>
    accountingProvider =
    NotifierProvider<AccountingNotifier, List<Transaction>>(
  AccountingNotifier.new,
);
