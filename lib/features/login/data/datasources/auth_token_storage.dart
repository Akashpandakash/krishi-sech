import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:krishi_sech/features/login/data/models/auth_session_model.dart';
import 'package:krishi_sech/features/login/domain/entities/auth_session.dart';

abstract interface class AuthTokenStorage {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}

class SecureAuthTokenStorage implements AuthTokenStorage {
  const SecureAuthTokenStorage([this._storage = const FlutterSecureStorage()]);

  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _userKey = 'auth_user';
  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    final values = await Future.wait([
      _storage.read(key: _accessKey),
      _storage.read(key: _refreshKey),
      _storage.read(key: _userKey),
    ]);
    if (values.any((value) => value == null)) return null;
    try {
      return AuthSession(
        user: AuthSessionModel.decodeUser(values[2]!),
        accessToken: values[0]!,
        refreshToken: values[1]!,
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) async {
    final model = AuthSessionModel.fromEntity(session);
    await Future.wait([
      _storage.write(key: _accessKey, value: session.accessToken),
      _storage.write(key: _refreshKey, value: session.refreshToken),
      _storage.write(key: _userKey, value: model.encodeUser()),
    ]);
  }

  @override
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
      _storage.delete(key: _userKey),
    ]);
  }
}
