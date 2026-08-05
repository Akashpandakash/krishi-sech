import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:krishi_sech/features/login/data/datasources/auth_remote_data_source.dart';
import 'package:krishi_sech/features/login/data/datasources/auth_token_storage.dart';
import 'package:krishi_sech/features/login/data/repositories/auth_repository_impl.dart';
import 'package:krishi_sech/features/login/domain/entities/auth_session.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/remote_crop_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/models/crop_model.dart';
import 'package:krishi_sech/features/my_crop/data/repositories/synced_crop_repository.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_repository.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('add crop sends UTC dates accepted by the backend', () async {
    late Map<String, dynamic> requestBody;
    final remote = _cropRemote((request) async {
      requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            ...requestBody,
            'id': 'crop-1',
            'userId': 'demo-farmer',
            'createdAt': '2026-08-05T21:00:00.000Z',
            'updatedAt': '2026-08-05T21:00:00.000Z',
          },
        }),
        201,
        headers: {'content-type': 'application/json'},
      );
    });
    final crop = CropModel(
      id: 'local-1',
      userId: 'demo-farmer',
      cropType: 'paddy',
      variety: 'Swarna',
      sowingDate: DateTime(2026, 8, 6),
      landArea: 2,
      landAreaUnit: 'acre',
      growthStage: 'sowing',
      healthStatus: 'healthy',
      irrigationType: 'manual',
      soilType: 'other',
      plantingMethod: 'other',
      createdAt: DateTime(2026, 8, 6),
      updatedAt: DateTime(2026, 8, 6),
    );

    final created = await remote.addCrop(crop);

    expect(requestBody['sowingDate'], endsWith('Z'));
    expect(created.id, 'crop-1');
    expect(created.cropType, 'paddy');
  });

  test('valid empty crop list is a successful response', () async {
    final remote = _cropRemote((_) async => _response(const []));

    final crops = await remote.getCrops();

    expect(crops, isEmpty);
  });

  test('retry re-fetches crops and clears a transient sync failure', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    var requests = 0;
    final remote = _cropRemote((_) async {
      requests += 1;
      return requests == 1
          ? _errorResponse(503, 'SERVICE_UNAVAILABLE')
          : _response(const []);
    });
    final repository = SyncedCropRepository(
      LocalCropDataSource(preferences),
      remote,
    );
    final controller = await CropController.load(repository);
    expect(controller.syncIssue, CropSyncIssue.server);

    await controller.refresh();

    expect(requests, 2);
    expect(controller.error, isNull);
    expect(controller.syncIssue, isNull);
    expect(controller.crops, isEmpty);
  });

  test('demo session uses backend token to load isolated crops', () async {
    final storage = _MemoryTokenStorage();
    final authRepository = AuthRepositoryImpl(
      AuthRemoteDataSource(
        baseUrl: 'http://127.0.0.1:3000',
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/verify-otp');
          return _authResponse();
        }),
      ),
      storage,
      demoModeEnabled: true,
    );
    final session = await authRepository.createDemoSession();
    var cropRequests = 0;
    final remote = RemoteCropDataSource(
      baseUrl: 'http://127.0.0.1:3000',
      accessTokenProvider: ({bool forceRefresh = false}) async =>
          session.accessToken,
      client: MockClient((request) async {
        cropRequests += 1;
        expect(request.headers['Authorization'], 'Bearer backend-demo-access');
        return _response(const []);
      }),
    );

    final crops = await remote.getCrops();

    expect(cropRequests, 1);
    expect(crops, isEmpty);
    expect(storage.session?.user.id, 'demo-farmer');
  });

  test('malformed crop response remains a server error', () async {
    final remote = _cropRemote((_) async => _response(const ['not-a-crop']));

    await expectLater(
      remote.getCrops(),
      throwsA(
        isA<CropRemoteFailure>().having(
          (failure) => failure.type,
          'type',
          CropRemoteFailureType.server,
        ),
      ),
    );
  });
}

RemoteCropDataSource _cropRemote(
  Future<http.Response> Function(http.Request) handler,
) => RemoteCropDataSource(
  baseUrl: 'http://127.0.0.1:3000',
  accessTokenProvider: ({bool forceRefresh = false}) async => 'valid-token',
  client: MockClient(handler),
);

http.Response _response(Object data) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  200,
  headers: {'content-type': 'application/json'},
);

http.Response _errorResponse(int status, String code) => http.Response(
  jsonEncode({
    'success': false,
    'error': {'code': code, 'message': 'Temporary failure'},
  }),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _authResponse() => http.Response(
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
      'accessToken': 'backend-demo-access',
      'refreshToken': 'backend-demo-refresh',
    },
  }),
  200,
  headers: {'content-type': 'application/json'},
);

class _MemoryTokenStorage implements AuthTokenStorage {
  AuthSession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> write(AuthSession session) async => this.session = session;
}
