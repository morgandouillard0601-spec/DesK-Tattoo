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

  String get fullName => '$firstName $lastName';

  String get initials {
    final String f = firstName.isNotEmpty ? firstName[0] : '';
    final String l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}
