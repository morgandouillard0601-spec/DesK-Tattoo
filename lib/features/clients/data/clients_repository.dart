import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/client.dart';

class ClientsNotifier extends Notifier<List<Client>> {
  @override
  List<Client> build() => List<Client>.from(_seed);

  static final DateTime _now = DateTime.now();

  static final List<Client> _seed = <Client>[
    Client(
      id: 'c1',
      firstName: 'Camille',
      lastName: 'Moreau',
      phone: '+33 6 12 34 56 78',
      email: 'camille.moreau@example.com',
      createdAt: _now.subtract(const Duration(days: 320)),
      lastVisit: _now.subtract(const Duration(days: 14)),
      totalSessions: 4,
      totalSpent: 920,
      notes: 'Préfère le black & grey. Sensible à la douleur sur les côtes.',
    ),
    Client(
      id: 'c2',
      firstName: 'Lucas',
      lastName: 'Bernard',
      phone: '+33 6 22 11 33 44',
      email: 'lucas.bernard@example.com',
      createdAt: _now.subtract(const Duration(days: 90)),
      lastVisit: _now.subtract(const Duration(days: 3)),
      totalSessions: 2,
      totalSpent: 480,
    ),
    Client(
      id: 'c3',
      firstName: 'Inès',
      lastName: 'Garcia',
      phone: '+33 7 88 99 12 34',
      email: 'ines.garcia@example.com',
      createdAt: _now.subtract(const Duration(days: 540)),
      lastVisit: _now.subtract(const Duration(days: 60)),
      totalSessions: 7,
      totalSpent: 2150,
      notes: 'Sleeve en cours, prochaine séance prévue.',
    ),
    Client(
      id: 'c4',
      firstName: 'Hugo',
      lastName: 'Petit',
      phone: '+33 6 45 67 89 01',
      email: 'hugo.petit@example.com',
      createdAt: _now.subtract(const Duration(days: 30)),
      totalSessions: 1,
      totalSpent: 180,
    ),
    Client(
      id: 'c5',
      firstName: 'Sofia',
      lastName: 'Martins',
      phone: '+33 7 11 22 33 44',
      email: 'sofia.martins@example.com',
      createdAt: _now.subtract(const Duration(days: 210)),
      lastVisit: _now.subtract(const Duration(days: 28)),
      totalSessions: 3,
      totalSpent: 760,
    ),
    Client(
      id: 'c6',
      firstName: 'Mathis',
      lastName: 'Lefevre',
      phone: '+33 6 98 76 54 32',
      email: 'mathis.lefevre@example.com',
      createdAt: _now.subtract(const Duration(days: 7)),
    ),
  ];

  Client? getById(String id) {
    for (final Client c in state) {
      if (c.id == id) return c;
    }
    return null;
  }

  List<Client> search(String query) {
    if (query.trim().isEmpty) return state;
    final String q = query.toLowerCase();
    return state
        .where(
          (Client c) =>
              c.fullName.toLowerCase().contains(q) ||
              c.phone.toLowerCase().contains(q) ||
              c.email.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  void add(Client client) {
    state = <Client>[...state, client];
  }
}

final NotifierProvider<ClientsNotifier, List<Client>> clientsProvider =
    NotifierProvider<ClientsNotifier, List<Client>>(ClientsNotifier.new);
