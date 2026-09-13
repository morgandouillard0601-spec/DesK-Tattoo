class Artist {
  const Artist({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.studioName,
    required this.specialties,
    required this.experienceYears,
    this.bio,
    this.instagram,
    this.avatarUrl,
    this.address = '',
    this.city = '',
    this.siret = '',
    this.role = ArtistRole.artist,
    this.subscriptionStatus = SubscriptionStatus.none,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.subscriptionCurrentPeriodEnd,
    this.onboardingCompletedAt,
    this.createdAt,
  });

  factory Artist.empty() => const Artist(
        id: '',
        firstName: '',
        lastName: '',
        email: '',
        phone: '',
        studioName: '',
        specialties: <String>[],
        experienceYears: 0,
      );

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json['id'] as String? ?? '',
      firstName: (json['firstName'] ?? json['first_name']) as String? ?? '',
      lastName: (json['lastName'] ?? json['last_name']) as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      studioName: (json['studioName'] ?? json['studio_name']) as String? ?? '',
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      experienceYears:
          (json['experienceYears'] ?? json['experience_years']) as int? ?? 0,
      bio: json['bio'] as String?,
      instagram: json['instagram'] as String?,
      avatarUrl: (json['avatarUrl'] ?? json['avatar_url']) as String?,
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      siret: json['siret'] as String? ?? '',
      role: ArtistRole.fromWire(
        (json['role'] as String?) ?? 'artist',
      ),
      subscriptionStatus: SubscriptionStatus.fromWire(
        (json['subscriptionStatus'] ?? json['subscription_status']) as String? ??
            'none',
      ),
      stripeCustomerId:
          (json['stripeCustomerId'] ?? json['stripe_customer_id']) as String?,
      stripeSubscriptionId: (json['stripeSubscriptionId'] ??
          json['stripe_subscription_id']) as String?,
      subscriptionCurrentPeriodEnd: _parseDate(
        json['subscriptionCurrentPeriodEnd'] ??
            json['subscription_current_period_end'],
      ),
      onboardingCompletedAt: _parseDate(
        json['onboardingCompletedAt'] ?? json['onboarding_completed_at'],
      ),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  static DateTime? _parseDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String studioName;
  final List<String> specialties;
  final int experienceYears;
  final String? bio;
  final String? instagram;
  final String? avatarUrl;
  final String address;
  final String city;
  final String siret;
  final ArtistRole role;
  final SubscriptionStatus subscriptionStatus;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final DateTime? subscriptionCurrentPeriodEnd;
  final DateTime? onboardingCompletedAt;
  final DateTime? createdAt;

  String get fullName => '$firstName $lastName'.trim();

  bool get isAdmin => role == ArtistRole.admin;

  bool get isEntitled =>
      isAdmin ||
      subscriptionStatus == SubscriptionStatus.active ||
      subscriptionStatus == SubscriptionStatus.trialing;

  bool get isComplete =>
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      studioName.trim().isNotEmpty &&
      address.trim().isNotEmpty &&
      city.trim().isNotEmpty &&
      siret.trim().isNotEmpty;

  String get initials {
    final String f = firstName.isNotEmpty ? firstName[0] : '';
    final String l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'studioName': studioName,
        'specialties': specialties,
        'experienceYears': experienceYears,
        'bio': bio,
        'instagram': instagram,
        'avatarUrl': avatarUrl,
        'address': address,
        'city': city,
        'siret': siret,
        'role': role.wire,
        'subscriptionStatus': subscriptionStatus.wire,
        'stripeCustomerId': stripeCustomerId,
        'stripeSubscriptionId': stripeSubscriptionId,
        'subscriptionCurrentPeriodEnd':
            subscriptionCurrentPeriodEnd?.toIso8601String(),
        'onboardingCompletedAt': onboardingCompletedAt?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
      };

  Map<String, dynamic> toSupabaseUpdate() => <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'studio_name': studioName,
        'address': address,
        'city': city,
        'siret': siret,
        'specialties': specialties,
        'experience_years': experienceYears,
        'bio': bio,
        'instagram': instagram,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

  Artist copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? studioName,
    List<String>? specialties,
    int? experienceYears,
    String? bio,
    String? instagram,
    String? avatarUrl,
    String? address,
    String? city,
    String? siret,
    ArtistRole? role,
    SubscriptionStatus? subscriptionStatus,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    DateTime? subscriptionCurrentPeriodEnd,
    DateTime? onboardingCompletedAt,
    DateTime? createdAt,
  }) {
    return Artist(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      studioName: studioName ?? this.studioName,
      specialties: specialties ?? this.specialties,
      experienceYears: experienceYears ?? this.experienceYears,
      bio: bio ?? this.bio,
      instagram: instagram ?? this.instagram,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      siret: siret ?? this.siret,
      role: role ?? this.role,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      subscriptionCurrentPeriodEnd:
          subscriptionCurrentPeriodEnd ?? this.subscriptionCurrentPeriodEnd,
      onboardingCompletedAt:
          onboardingCompletedAt ?? this.onboardingCompletedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum ArtistRole {
  artist,
  admin;

  String get wire => name;

  static ArtistRole fromWire(String value) =>
      value == 'admin' ? ArtistRole.admin : ArtistRole.artist;
}

enum SubscriptionStatus {
  none,
  active,
  pastDue,
  canceled,
  incomplete,
  trialing;

  String get wire => switch (this) {
        SubscriptionStatus.none => 'none',
        SubscriptionStatus.active => 'active',
        SubscriptionStatus.pastDue => 'past_due',
        SubscriptionStatus.canceled => 'canceled',
        SubscriptionStatus.incomplete => 'incomplete',
        SubscriptionStatus.trialing => 'trialing',
      };

  static SubscriptionStatus fromWire(String value) => switch (value) {
        'active' => SubscriptionStatus.active,
        'past_due' => SubscriptionStatus.pastDue,
        'canceled' => SubscriptionStatus.canceled,
        'incomplete' => SubscriptionStatus.incomplete,
        'trialing' => SubscriptionStatus.trialing,
        _ => SubscriptionStatus.none,
      };

  String get labelFr => switch (this) {
        SubscriptionStatus.none => 'Non abonné',
        SubscriptionStatus.active => 'Actif',
        SubscriptionStatus.pastDue => 'Paiement en échec',
        SubscriptionStatus.canceled => 'Résilié',
        SubscriptionStatus.incomplete => 'Incomplet',
        SubscriptionStatus.trialing => 'Essai',
      };
}
