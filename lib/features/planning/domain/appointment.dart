import 'package:flutter/material.dart';

enum AppointmentStatus { scheduled, confirmed, inProgress, completed, cancelled }

extension AppointmentStatusX on AppointmentStatus {
  String get label => switch (this) {
        AppointmentStatus.scheduled => 'Planifié',
        AppointmentStatus.confirmed => 'Confirmé',
        AppointmentStatus.inProgress => 'En cours',
        AppointmentStatus.completed => 'Terminé',
        AppointmentStatus.cancelled => 'Annulé',
      };

  Color color(ColorScheme scheme) => switch (this) {
        AppointmentStatus.scheduled => scheme.tertiary,
        AppointmentStatus.confirmed => scheme.primary,
        AppointmentStatus.inProgress => scheme.secondary,
        AppointmentStatus.completed => scheme.outline,
        AppointmentStatus.cancelled => scheme.error,
      };
}

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
}
