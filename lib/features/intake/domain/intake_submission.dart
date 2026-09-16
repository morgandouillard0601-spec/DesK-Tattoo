import 'package:intl/intl.dart';

/// En-tête du studio affiché dans le formulaire public, renvoyé par la
/// function `intake-artist` à partir du token du QR code.
class IntakeStudio {
  const IntakeStudio({
    required this.studioName,
    required this.artistName,
    required this.city,
  });

  factory IntakeStudio.fromJson(Map<String, dynamic> json) {
    final String first = (json['first_name'] as String?) ?? '';
    final String last = (json['last_name'] as String?) ?? '';
    return IntakeStudio(
      studioName: (json['studio_name'] as String?) ?? '',
      artistName: '$first $last'.trim(),
      city: (json['city'] as String?) ?? '',
    );
  }

  final String studioName;
  final String artistName;
  final String city;

  String get displayName =>
      studioName.trim().isNotEmpty ? studioName : artistName;
}

/// Ce que le client remplit sur son téléphone avant de signer.
class IntakeSubmission {
  const IntakeSubmission({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.healthAnswers,
    required this.acceptedFlags,
  });

  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String postalCode;
  final Map<String, String> healthAnswers;
  final Map<String, bool> acceptedFlags;

  String get fullName => '$firstName $lastName'.trim();

  bool accepted(String key) => acceptedFlags[key] ?? false;

  Map<String, dynamic> toRequestBody({
    required String token,
    required String signatureBase64,
    required String? pdfBase64,
  }) {
    return <String, dynamic>{
      'token': token,
      'first_name': firstName,
      'last_name': lastName,
      'birth_date': DateFormat('yyyy-MM-dd').format(birthDate),
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'postal_code': postalCode,
      'health_answers': healthAnswers,
      'accepted_terms': accepted('accepted_terms'),
      'accepted_health': accepted('accepted_health'),
      'accepted_aftercare': accepted('accepted_aftercare'),
      'accepted_image_rights': accepted('accepted_image_rights'),
      'signature_png': signatureBase64,
      'pdf': ?pdfBase64,
    };
  }
}

/// Âge révolu, utilisé pour bloquer les mineurs.
int ageOn(DateTime birthDate, DateTime reference) {
  int age = reference.year - birthDate.year;
  final bool beforeBirthday = reference.month < birthDate.month ||
      (reference.month == birthDate.month && reference.day < birthDate.day);
  if (beforeBirthday) age -= 1;
  return age;
}
