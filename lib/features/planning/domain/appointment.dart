import 'package:flutter/material.dart';

import '../../../core/data/artist_scoped_notifier.dart';

enum AppointmentStatus { scheduled, confirmed, inProgress, completed, cancelled }

extension AppointmentStatusX on AppointmentStatus {
  String get label => switch (this) {
        AppointmentStatus.scheduled => 'Planifié',
        AppointmentStatus.confirmed => 'Confirmé',
        AppointmentStatus.inProgress => 'En cours',
        AppointmentStatus.completed => 'Terminé',
        AppointmentStatus.cancelled => 'Annulé',
      };

  /// Valeur attendue par la contrainte CHECK de `public.appointments`.
  /// Attention : `inProgress` s'écrit `in_progress` en base.
  String get wire => switch (this) {
        AppointmentStatus.scheduled => 'scheduled',
        AppointmentStatus.confirmed => 'confirmed',
        AppointmentStatus.inProgress => 'in_progress',
        AppointmentStatus.completed => 'completed',
        AppointmentStatus.cancelled => 'cancelled',
      };

  Color color(ColorScheme scheme) => switch (this) {
        AppointmentStatus.scheduled => scheme.tertiary,
        AppointmentStatus.confirmed => scheme.primary,
        AppointmentStatus.inProgress => scheme.secondary,
        AppointmentStatus.completed => scheme.outline,
        AppointmentStatus.cancelled => scheme.error,
      };
}

AppointmentStatus appointmentStatusFromWire(String? value) =>
    switch (value) {
      'confirmed' => AppointmentStatus.confirmed,
      'in_progress' => AppointmentStatus.inProgress,
      'completed' => AppointmentStatus.completed,
      'cancelled' => AppointmentStatus.cancelled,
      _ => AppointmentStatus.scheduled,
    };

class Appointment {
  const Appointment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.title,
    required this.start,
    required this.duration,
    required this.price,
    required this.status,
    this.notes,
  });

  factory Appointment.fromSupabase(Map<String, dynamic> row) {
    return Appointment(
      id: readString(row['id']),
      clientId: readString(row['client_id']),
      clientName: readString(row['client_name']),
      title: readString(row['title']),
      start: readDate(row['start_at']) ?? DateTime.now(),
      duration: Duration(minutes: readInt(row['duration_minutes'])),
      price: readDouble(row['price']),
      status: appointmentStatusFromWire(row['status'] as String?),
      notes: row['notes'] as String?,
    );
  }

  final String id;
  final String clientId;
  final String clientName;
  final String title;
  final DateTime start;
  final Duration duration;
  final double price;
  final AppointmentStatus status;
  final String? notes;

  DateTime get end => start.add(duration);

  /// Payload d'écriture (l'`artist_id` est ajouté par le repository).
  Map<String, dynamic> toSupabase() => <String, dynamic>{
        'client_id': clientId.isEmpty ? null : clientId,
        'client_name': clientName,
        'title': title,
        'start_at': start.toIso8601String(),
        'duration_minutes': duration.inMinutes,
        'price': price,
        'status': status.wire,
        'notes': notes,
      };

  Appointment copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? title,
    DateTime? start,
    Duration? duration,
    double? price,
    AppointmentStatus? status,
    String? notes,
  }) {
    return Appointment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      title: title ?? this.title,
      start: start ?? this.start,
      duration: duration ?? this.duration,
      price: price ?? this.price,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
