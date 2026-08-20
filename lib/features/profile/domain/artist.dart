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
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      studioName: json['studioName'] as String? ?? '',
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      experienceYears: json['experienceYears'] as int? ?? 0,
      bio: json['bio'] as String?,
      instagram: json['instagram'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
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

  String get fullName => '$firstName $lastName'.trim();

  bool get isComplete =>
      firstName.trim().isNotEmpty &&
      lastName.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      studioName.trim().isNotEmpty;

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
    );
  }
}
