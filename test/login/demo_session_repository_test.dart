import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:krishi_sech/features/login/data/datasources/auth_remote_data_source.dart';
import 'package:krishi_sech/features/login/data/datasources/auth_token_storage.dart';
import 'package:krishi_sech/features/login/data/repositories/auth_repository_impl.dart';
import 'package:krishi_sech/features/login/domain/entities/auth_session.dart';
import 'package:krishi_sech/features/login/domain/repositories/auth_repository.dart';

void main() {
  test('creates and stores a backend-issued demo session', () async {
    var backendRequests = 0;
    final storage = _MemoryTokenStorage();
    final repository = AuthRepositoryImpl(
      AuthRemoteDataSource(
        baseUrl: 'http://127.0.0.1:3000',
        client: MockClient((request) async {
          backendRequests += 1;
          expect(request.url.path, '/api/auth/verify-otp');
          expect(request.headers['X-Krishi-Development-Client'], 'true');
          return http.Response(
            '{"success":true,"data":{"user":{"id":"demo-farmer","phone":"+919999999999","name":"Demo Farmer","preferredLanguage":"en","isActive":true},"accessToken":"backend-access-token","refreshToken":"backend-refresh-token"}}',
            200,
          );
        }),
      ),
      storage,
      demoModeEnabled: true,
    );

    final session = await repository.createDemoSession();

    expect(backendRequests, 1);
    expect(storage.session, same(session));
    expect(session.user.id, 'demo-farmer');
    expect(session.user.name, 'Demo Farmer');
    expect(session.user.preferredLanguage, 'en');
    expect(session.accessToken, 'backend-access-token');
    expect(session.refreshToken, 'backend-refresh-token');
  });

  test('release configuration rejects local demo session', () async {
    var backendRequests = 0;
    final storage = _MemoryTokenStorage();
    final repository = AuthRepositoryImpl(
      AuthRemoteDataSource(
        baseUrl: 'http://127.0.0.1:3000',
        client: MockClient((_) async {
          backendRequests += 1;
          return http.Response('', 500);
        }),
      ),
      storage,
      demoModeEnabled: false,
    );

    await expectLater(
      repository.createDemoSession(),
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.type,
          'type',
          AuthFailureType.unauthorized,
        ),
      ),
    );
    expect(backendRequests, 0);
    expect(storage.session, isNull);
  });

  test('backend demo session restores after app restart', () async {
    final storage = _MemoryTokenStorage();
    final accessToken = _jwtExpiringIn(const Duration(minutes: 15));
    var verifyRequests = 0;
    var meRequests = 0;
    final remote = AuthRemoteDataSource(
      baseUrl: 'http://127.0.0.1:3000',
      client: MockClient((request) async {
        if (request.url.path == '/api/auth/verify-otp') {
          verifyRequests += 1;
          return _sessionResponse(accessToken);
        }
        if (request.url.path == '/api/auth/me') {
          meRequests += 1;
          expect(request.headers['Authorization'], 'Bearer $accessToken');
          return http.Response(
            '{"success":true,"data":{"id":"demo-farmer","phone":"+919999999999","name":"Demo Farmer","preferredLanguage":"en","isActive":true}}',
            200,
          );
        }
        return http.Response('', 404);
      }),
    );
    final firstRun = AuthRepositoryImpl(remote, storage, demoModeEnabled: true);
    await firstRun.createDemoSession();

    final restarted = AuthRepositoryImpl(
      remote,
      storage,
      demoModeEnabled: true,
    );
    final restored = await restarted.restoreSession();

    expect(verifyRequests, 1);
    expect(meRequests, 1);
    expect(restored?.user.id, 'demo-farmer');
    expect(restored?.accessToken, accessToken);
    expect(storage.session, isNotNull);
  });
}

http.Response _sessionResponse(String accessToken) => http.Response(
  jsonEncode({
    'success': true,
    'data': {
      'user': {
        'id': 'demo-farmer',
        'phone': '+919999999999',
        'name': 'Demo Farmer',
        'preferredLanguage': 'en',
        'isActive': true,
      },
      'accessToken': accessToken,
      'refreshToken': 'backend-refresh-token',
    },
  }),
  200,
);

String _jwtExpiringIn(Duration duration) {
  String encode(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiresAt = DateTime.now().add(duration).millisecondsSinceEpoch ~/ 1000;
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${encode({'sub': 'demo-farmer', 'exp': expiresAt})}.test-signature';
}

class _MemoryTokenStorage implements AuthTokenStorage {
  AuthSession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> write(AuthSession session) async => this.session = session;
}
