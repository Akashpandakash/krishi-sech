import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:krishi_sech/features/login/data/datasources/auth_remote_data_source.dart';
import 'package:krishi_sech/features/login/data/datasources/auth_token_storage.dart';
import 'package:krishi_sech/features/login/data/repositories/auth_repository_impl.dart';
import 'package:krishi_sech/features/login/domain/entities/auth_session.dart';
import 'package:krishi_sech/features/login/domain/repositories/auth_repository.dart';

void main() {
  test('creates and stores demo session without any backend request', () async {
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
      demoModeEnabled: true,
    );

    final session = await repository.createDemoSession();

    expect(backendRequests, 0);
    expect(storage.session, same(session));
    expect(session.user.id, 'demo-farmer');
    expect(session.user.name, 'Demo Farmer');
    expect(session.user.preferredLanguage, 'en');
    expect(session.accessToken.split('.'), hasLength(3));
    expect(session.refreshToken, isNotEmpty);
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
