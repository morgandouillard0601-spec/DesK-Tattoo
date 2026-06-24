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
  });

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

  String get fullName => '$firstName $lastName';

  String get initials {
    final String f = firstName.isNotEmpty ? firstName[0] : '';
    final String l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }
}
