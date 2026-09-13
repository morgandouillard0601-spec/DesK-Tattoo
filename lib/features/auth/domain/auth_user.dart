class AuthUser {
  const AuthUser({
    required this.email,
    this.id,
  });

  final String email;
  final String? id;
}
