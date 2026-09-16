import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/artist_scoped_notifier.dart';
import '../domain/appointment.dart';

class PlanningNotifier extends ArtistScopedNotifier<Appointment> {
  @override
  String get table => 'appointments';

  @override
  String get orderColumn => 'start_at';

  @override
  bool get orderAscending => true;

  @override
  Appointment fromRow(Map<String, dynamic> row) =>
      Appointment.fromSupabase(row);

  List<Appointment> forDay(DateTime day) {
    return items
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
        items.where((Appointment a) => a.clientId == clientId).toList();
    list.sort((Appointment a, Appointment b) => b.start.compareTo(a.start));
    return list;
  }

  Future<void> add(Appointment appointment) =>
      insertRow(appointment.toSupabase());

  /// Nommée `save` et non `update` : `AsyncNotifier` expose déjà `update`.
  Future<void> save(Appointment appointment) =>
      updateRow(appointment.id, appointment.toSupabase());

  Future<void> delete(String id) => deleteRow(id);
}

final AsyncNotifierProvider<PlanningNotifier, List<Appointment>>
    planningProvider =
    AsyncNotifierProvider<PlanningNotifier, List<Appointment>>(
  PlanningNotifier.new,
);
