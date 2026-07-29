import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/appointment.dart';

class PlanningNotifier extends Notifier<List<Appointment>> {
  @override
  List<Appointment> build() => List<Appointment>.from(_seed);

  static DateTime _at(int dayOffset, int hour, [int minute = 0]) {
    final DateTime now = DateTime.now();
    final DateTime base = DateTime(now.year, now.month, now.day);
    return base.add(Duration(days: dayOffset, hours: hour, minutes: minute));
  }

  static final List<Appointment> _seed = <Appointment>[
    Appointment(
      id: 'a1',
      clientId: 'c1',
      clientName: 'Camille Moreau',
      title: 'Retouche rose épaule',
      start: _at(0, 10),
      duration: const Duration(hours: 1, minutes: 30),
      price: 150,
      status: AppointmentStatus.confirmed,
      notes: 'Retouche couleurs + ombrage léger.',
    ),
    Appointment(
      id: 'a2',
      clientId: 'c2',
      clientName: 'Lucas Bernard',
      title: 'Lettrage avant-bras',
      start: _at(0, 13),
      duration: const Duration(hours: 2),
      price: 280,
      status: AppointmentStatus.scheduled,
    ),
    Appointment(
      id: 'a3',
      clientId: 'c3',
      clientName: 'Inès Garcia',
      title: 'Session sleeve 4/6',
      start: _at(0, 16),
      duration: const Duration(hours: 3),
      price: 420,
      status: AppointmentStatus.confirmed,
      notes: 'Apporter référence pivoines.',
    ),
    Appointment(
      id: 'a4',
      clientId: 'c5',
      clientName: 'Sofia Martins',
      title: 'Mini tatouage poignet',
      start: _at(1, 11),
      duration: const Duration(minutes: 45),
      price: 90,
      status: AppointmentStatus.scheduled,
    ),
    Appointment(
      id: 'a5',
      clientId: 'c4',
      clientName: 'Hugo Petit',
      title: 'Consultation projet dos',
      start: _at(1, 15),
      duration: const Duration(minutes: 30),
      price: 0,
      status: AppointmentStatus.scheduled,
    ),
    Appointment(
      id: 'a6',
      clientId: 'c6',
      clientName: 'Mathis Lefevre',
      title: 'Black work mollet',
      start: _at(2, 10),
      duration: const Duration(hours: 2, minutes: 30),
      price: 350,
      status: AppointmentStatus.confirmed,
    ),
    Appointment(
      id: 'a7',
      clientId: 'c1',
      clientName: 'Camille Moreau',
      title: 'Suivi cicatrisation',
      start: _at(3, 17),
      duration: const Duration(minutes: 20),
      price: 0,
      status: AppointmentStatus.scheduled,
    ),
    Appointment(
      id: 'a8',
      clientId: 'c2',
      clientName: 'Lucas Bernard',
      title: 'Session géométrique',
      start: _at(-1, 14),
      duration: const Duration(hours: 2),
      price: 320,
      status: AppointmentStatus.completed,
    ),
  ];

  List<Appointment> forDay(DateTime day) {
    return state
        .where(
          (Appointment a) =>
              a.start.year == day.year &&
              a.start.month == day.month &&
              a.start.day == day.day,
        )
        .toList(growable: false)
      ..sort((Appointment a, Appointment b) => a.start.compareTo(b.start));
  }

  List<Appointment> forClient(String clientId) {
    final List<Appointment> list =
        state.where((Appointment a) => a.clientId == clientId).toList();
    list.sort((Appointment a, Appointment b) => b.start.compareTo(a.start));
    return list;
  }

  void add(Appointment appointment) {
    state = <Appointment>[...state, appointment];
  }

  void update(Appointment appointment) {
    state = <Appointment>[
      for (final Appointment a in state)
        if (a.id == appointment.id) appointment else a,
    ];
  }

  void delete(String id) {
    state =
        state.where((Appointment a) => a.id != id).toList(growable: false);
  }
}

final NotifierProvider<PlanningNotifier, List<Appointment>> planningProvider =
    NotifierProvider<PlanningNotifier, List<Appointment>>(
  PlanningNotifier.new,
);
