import 'dart:convert';

import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/features/login/data/datasources/auth_remote_data_source.dart';
import 'package:krishi_sech/features/login/data/datasources/auth_token_storage.dart';
import 'package:krishi_sech/features/login/domain/entities/auth_session.dart';
import 'package:krishi_sech/features/login/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(
    this.remote,
    this.storage, {
    this.demoModeEnabled = AppEnvironment.demoModeEnabled,
  });

  final AuthRemoteDataSource remote;
  final AuthTokenStorage storage;
  final bool demoModeEnabled;

  @override
  Future<OtpDispatch> sendOtp(String phone) => remote.sendOtp(phone);

  @override
  Future<AuthSession> verifyOtp(String phone, String otp) async {
    final session = await remote.verifyOtp(phone, otp);
    await storage.write(session);
    return session;
  }

  @override
  Future<AuthSession> createDemoSession() async {
    if (!demoModeEnabled) {
      throw const AuthFailure(
        AuthFailureType.unauthorized,
        'Demo mode is unavailable',
      );
    }
    final now = DateTime.now();
    final session = AuthSession(
      user: const AuthUser(
        id: 'demo-farmer',
        phone: '+919999999999',
        name: 'Demo Farmer',
        preferredLanguage: 'en',
        isActive: true,
      ),
      accessToken: _demoAccessToken(now),
      refreshToken: 'demo-refresh-${now.microsecondsSinceEpoch}',
    );
    await storage.write(session);
    return session;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final stored = await storage.read();
    if (stored == null) return null;
    if (!_isExpired(stored.accessToken)) {
      try {
        final user = await remote.me(stored.accessToken);
        return AuthSession(
          user: user,
          accessToken: stored.accessToken,
          refreshToken: stored.refreshToken,
        );
      } on AuthFailure catch (failure) {
        if (failure.type == AuthFailureType.offline ||
            failure.type == AuthFailureType.timeout) {
          return stored;
        }
        if (failure.type != AuthFailureType.unauthorized) rethrow;
      }
    }
    try {
      final refreshed = await remote.refresh(stored.refreshToken);
      await storage.write(refreshed);
      return refreshed;
    } on AuthFailure catch (failure) {
      if (failure.type == AuthFailureType.offline ||
          failure.type == AuthFailureType.timeout) {
        return null;
      }
      await storage.clear();
      return null;
    }
  }

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    final stored = await storage.read();
    if (stored == null) return null;
    if (!forceRefresh && !_isExpired(stored.accessToken)) {
      return stored.accessToken;
    }
    final refreshed = await remote.refresh(stored.refreshToken);
    await storage.write(refreshed);
    return refreshed.accessToken;
  }

  @override
  Future<void> logout() async {
    final stored = await storage.read();
    try {
      if (stored != null) await remote.logout(stored.refreshToken);
    } finally {
      await storage.clear();
    }
  }

  bool _isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final expiresAt = payload is Map<String, dynamic> ? payload['exp'] : null;
      return expiresAt is! num ||
          DateTime.fromMillisecondsSinceEpoch(
            expiresAt.toInt() * 1000,
          ).isBefore(DateTime.now().add(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }

  String _demoAccessToken(DateTime now) {
    String encode(Map<String, Object> value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    return '${encode({'alg': 'none', 'typ': 'JWT'})}.'
        '${encode({'sub': 'demo-farmer', 'demo': true, 'iat': now.millisecondsSinceEpoch ~/ 1000, 'exp': now.add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000})}.development-only';
  }
}
