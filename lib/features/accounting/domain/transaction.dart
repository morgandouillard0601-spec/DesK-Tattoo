import 'package:flutter/material.dart';

import '../../../core/data/artist_scoped_notifier.dart';

enum TransactionType { income, expense }

enum PaymentMethod { cash, card, transfer, deposit }

TransactionType transactionTypeFromWire(String? value) =>
    value == 'expense' ? TransactionType.expense : TransactionType.income;

PaymentMethod paymentMethodFromWire(String? value) {
  for (final PaymentMethod m in PaymentMethod.values) {
    if (m.name == value) return m;
  }
  return PaymentMethod.cash;
}

extension TransactionTypeX on TransactionType {
  /// Valeur attendue par la contrainte CHECK de `public.transactions`.
  String get wire => name;
}

extension PaymentMethodX on PaymentMethod {
  /// Valeur attendue par la contrainte CHECK de `public.transactions`.
  String get wire => name;

  String get label => switch (this) {
        PaymentMethod.cash => 'Espèces',
        PaymentMethod.card => 'Carte',
        PaymentMethod.transfer => 'Virement',
        PaymentMethod.deposit => 'Acompte',
      };

  IconData get icon => switch (this) {
        PaymentMethod.cash => Icons.payments_rounded,
        PaymentMethod.card => Icons.credit_card_rounded,
        PaymentMethod.transfer => Icons.account_balance_rounded,
        PaymentMethod.deposit => Icons.savings_rounded,
      };
}

class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.label,
    required this.amount,
    required this.date,
    required this.method,
    this.clientId,
    this.clientName,
    this.category,
  });

  factory Transaction.fromSupabase(Map<String, dynamic> row) {
    return Transaction(
      id: readString(row['id']),
      type: transactionTypeFromWire(row['type'] as String?),
      label: readString(row['label']),
      amount: readDouble(row['amount']),
      date: readDate(row['date']) ?? DateTime.now(),
      method: paymentMethodFromWire(row['method'] as String?),
      clientId: row['client_id'] as String?,
      clientName: row['client_name'] as String?,
      category: row['category'] as String?,
    );
  }

  final String id;
  final TransactionType type;
  final String label;
  final double amount;
  final DateTime date;
  final PaymentMethod method;
  final String? clientId;
  final String? clientName;
  final String? category;

  double get signedAmount => type == TransactionType.income ? amount : -amount;

  /// Payload d'écriture (l'`artist_id` est ajouté par le repository).
  /// `transactions.date` est une colonne `date` : on n'envoie que le jour.
  Map<String, dynamic> toSupabase() => <String, dynamic>{
        'type': type.wire,
        'label': label,
        'amount': amount,
        'date': date.toIso8601String().split('T').first,
        'method': method.wire,
        'client_id': clientId,
        'client_name': clientName,
        'category': category,
      };

  Transaction copyWith({
    String? id,
    TransactionType? type,
    String? label,
    double? amount,
    DateTime? date,
    PaymentMethod? method,
    String? clientId,
    String? clientName,
    String? category,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: method ?? this.method,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      category: category ?? this.category,
    );
  }
}
