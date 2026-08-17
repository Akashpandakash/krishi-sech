import 'dart:convert';

import 'package:krishi_sech/features/login/domain/entities/auth_session.dart';

class AuthSessionModel {
  const AuthSessionModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AuthUser user;
  final String accessToken;
  final String refreshToken;

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Invalid authentication user');
    }
    return AuthSessionModel(
      user: AuthUser(
        id: _string(user, 'id'),
        phone: user['phone'] as String?,
        name: user['name'] as String?,
        preferredLanguage: _string(user, 'preferredLanguage'),
        isActive: user['isActive'] as bool? ?? false,
      ),
      accessToken: _string(json, 'accessToken'),
      refreshToken: _string(json, 'refreshToken'),
    );
  }

  factory AuthSessionModel.fromEntity(AuthSession session) => AuthSessionModel(
    user: session.user,
    accessToken: session.accessToken,
    refreshToken: session.refreshToken,
  );

  AuthSession toEntity() => AuthSession(
    user: user,
    accessToken: accessToken,
    refreshToken: refreshToken,
  );

  String encodeUser() => jsonEncode({
    'id': user.id,
    'phone': user.phone,
    'name': user.name,
    'preferredLanguage': user.preferredLanguage,
    'isActive': user.isActive,
  });

  static AuthUser decodeUser(String value) {
    final json = jsonDecode(value);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid stored user');
    }
    return AuthUser(
      id: _string(json, 'id'),
      phone: json['phone'] as String?,
      name: json['name'] as String?,
      preferredLanguage: _string(json, 'preferredLanguage'),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  static String _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid $key');
    }
    return value;
  }
}
