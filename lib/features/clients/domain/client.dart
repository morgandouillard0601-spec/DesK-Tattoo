import '../../../core/data/artist_scoped_notifier.dart';

/// Provenance de la fiche client.
enum ClientSource {
  /// Créée à la main par le tatoueur depuis l'app.
  manual,

  /// Remplie par le client lui-même après scan du QR d'accueil.
  intake;

  String get wire => name;

  static ClientSource fromWire(String? value) =>
      value == 'intake' ? ClientSource.intake : ClientSource.manual;
}

class Client {
  const Client({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.createdAt,
    this.lastVisit,
    this.notes,
    this.totalSessions = 0,
    this.totalSpent = 0,
    this.source = ClientSource.manual,
    this.birthDate,
    this.address = '',
    this.city = '',
    this.postalCode = '',
  });

  factory Client.fromSupabase(Map<String, dynamic> row) {
    return Client(
      id: readString(row['id']),
      firstName: readString(row['first_name']),
      lastName: readString(row['last_name']),
      phone: readString(row['phone']),
      email: readString(row['email']),
      createdAt: readDate(row['created_at']) ?? DateTime.now(),
      lastVisit: readDate(row['last_visit']),
      notes: row['notes'] as String?,
      totalSessions: readInt(row['total_sessions']),
      totalSpent: readDouble(row['total_spent']),
      source: ClientSource.fromWire(row['source'] as String?),
      birthDate: readDate(row['birth_date']),
      address: readString(row['address']),
      city: readString(row['city']),
      postalCode: readString(row['postal_code']),
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final DateTime createdAt;
  final DateTime? lastVisit;
  final String? notes;
  final int totalSessions;
  final double totalSpent;
  final ClientSource source;
  final DateTime? birthDate;
  final String address;
  final String city;
  final String postalCode;

  String get fullName => '$firstName $lastName'.trim();

  bool get isFromIntake => source == ClientSource.intake;

  String get initials {
    final String f = firstName.isNotEmpty ? firstName[0] : '';
    final String l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  /// Adresse sur une ligne, ou chaîne vide si rien n'est renseigné.
  String get addressLine {
    final List<String> parts = <String>[
      if (address.trim().isNotEmpty) address.trim(),
      if (postalCode.trim().isNotEmpty) postalCode.trim(),
      if (city.trim().isNotEmpty) city.trim(),
    ];
    return parts.join(' · ');
  }

  /// Payload d'écriture (l'`artist_id` est ajouté par le repository).
  Map<String, dynamic> toSupabase() => <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'email': email,
        'notes': notes,
        'total_sessions': totalSessions,
        'total_spent': totalSpent,
        'source': source.wire,
        'birth_date': birthDate?.toIso8601String().split('T').first,
        'address': address,
        'city': city,
        'postal_code': postalCode,
        'last_visit': lastVisit?.toIso8601String(),
      };

  Client copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    DateTime? createdAt,
    DateTime? lastVisit,
    String? notes,
    int? totalSessions,
    double? totalSpent,
    ClientSource? source,
    DateTime? birthDate,
    String? address,
    String? city,
    String? postalCode,
  }) {
    return Client(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastVisit: lastVisit ?? this.lastVisit,
      notes: notes ?? this.notes,
      totalSessions: totalSessions ?? this.totalSessions,
      totalSpent: totalSpent ?? this.totalSpent,
      source: source ?? this.source,
      birthDate: birthDate ?? this.birthDate,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
    );
  }
}
