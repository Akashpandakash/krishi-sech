class AuthUser {
  const AuthUser({
    required this.id,
    required this.phone,
    required this.preferredLanguage,
    required this.isActive,
    this.name,
  });

  final String id;
  final String phone;
  final String? name;
  final String preferredLanguage;
  final bool isActive;
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AuthUser user;
  final String accessToken;
  final String refreshToken;
}
