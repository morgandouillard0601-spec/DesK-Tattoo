import 'package:flutter/material.dart';

enum TransactionType { income, expense }

enum PaymentMethod { cash, card, transfer, deposit }

extension PaymentMethodX on PaymentMethod {
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
    this.clientName,
    this.category,
  });

  final String id;
  final TransactionType type;
  final String label;
  final double amount;
  final DateTime date;
  final PaymentMethod method;
  final String? clientName;
  final String? category;

  double get signedAmount => type == TransactionType.income ? amount : -amount;
}
