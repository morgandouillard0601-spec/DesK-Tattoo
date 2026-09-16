/// Contrat de consentement signé par un client via le QR d'accueil.
class ClientConsent {
  const ClientConsent({
    required this.id,
    required this.clientId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.signedAt,
    required this.acceptedTerms,
    required this.acceptedHealth,
    required this.acceptedAftercare,
    required this.acceptedImageRights,
    required this.healthAnswers,
    this.birthDate,
    this.pdfPath,
    this.signaturePath,
  });

  factory ClientConsent.fromSupabase(Map<String, dynamic> row) {
    return ClientConsent(
      id: row['id'] as String,
      clientId: row['client_id'] as String? ?? '',
      fullName: row['full_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      phone: row['phone'] as String? ?? '',
      signedAt:
          DateTime.tryParse(row['signed_at']?.toString() ?? '') ??
              DateTime.now(),
      acceptedTerms: row['accepted_terms'] == true,
      acceptedHealth: row['accepted_health'] == true,
      acceptedAftercare: row['accepted_aftercare'] == true,
      acceptedImageRights: row['accepted_image_rights'] == true,
      healthAnswers: _readHealthAnswers(row['health_answers']),
      birthDate: DateTime.tryParse(row['birth_date']?.toString() ?? ''),
      pdfPath: row['pdf_path'] as String?,
      signaturePath: row['signature_path'] as String?,
    );
  }

  static Map<String, String> _readHealthAnswers(Object? raw) {
    if (raw is Map) {
      return <String, String>{
        for (final MapEntry<Object?, Object?> e in raw.entries)
          e.key.toString(): e.value?.toString() ?? '',
      };
    }
    return const <String, String>{};
  }

  final String id;
  final String clientId;
  final String fullName;
  final String email;
  final String phone;
  final DateTime signedAt;
  final bool acceptedTerms;
  final bool acceptedHealth;
  final bool acceptedAftercare;
  final bool acceptedImageRights;
  final Map<String, String> healthAnswers;
  final DateTime? birthDate;
  final String? pdfPath;
  final String? signaturePath;

  bool get hasPdf => pdfPath != null && pdfPath!.trim().isNotEmpty;

  /// Réponses santé réellement renseignées par le client.
  Map<String, String> get filledHealthAnswers => <String, String>{
        for (final MapEntry<String, String> e in healthAnswers.entries)
          if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
      };
}
