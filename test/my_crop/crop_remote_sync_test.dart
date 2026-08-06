import 'dart:convert';
import 'dart:io';

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
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_task_controller.dart';
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

  test(
    'create uses the server ID, refreshes the list, and persists after restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      Map<String, dynamic>? createdPayload;
      var listRequests = 0;
      final remote = _cropRemote((request) async {
        if (request.method == 'POST') {
          createdPayload = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                ...createdPayload!,
                'id': 'server-crop-1',
                'userId': 'demo-farmer',
                'createdAt': '2026-08-06T12:00:00.000Z',
                'updatedAt': '2026-08-06T12:00:00.000Z',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        listRequests += 1;
        return _response(
          createdPayload == null
              ? const []
              : [
                  {
                    ...createdPayload!,
                    'id': 'server-crop-1',
                    'userId': 'demo-farmer',
                    'createdAt': '2026-08-06T12:00:00.000Z',
                    'updatedAt': '2026-08-06T12:00:00.000Z',
                  },
                ],
        );
      });
      final local = LocalCropDataSource(preferences);
      final controller = await CropController.load(
        SyncedCropRepository(local, remote),
      );
      final localCrop = Crop(
        id: 'temporary-local-id',
        userId: 'demo-farmer',
        kind: CropKind.wheat,
        variety: 'HD-2967',
        sowingDate: DateTime(2026, 8, 1),
        landArea: 1.5,
        landAreaUnit: LandAreaUnit.acre,
        growthStage: GrowthStage.germination,
        irrigationType: IrrigationType.manual,
      );

      expect(await controller.addCrop(localCrop), isTrue);
      expect(controller.crops.single.id, 'server-crop-1');
      expect(controller.crops.single.variety, 'HD-2967');

      await controller.refresh();
      expect(listRequests, 2);
      expect(controller.crops.single.id, 'server-crop-1');

      final restored = await local.getCrops();
      expect(restored.single.id, 'server-crop-1');
      expect(restored.single.variety, 'HD-2967');
    },
  );

  test(
    'ambiguous create retry reuses one idempotency key and generates tasks once',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      const requestId = '913b03bd-f33f-45a4-9817-15f5564f5534';
      Map<String, dynamic>? serverCrop;
      var createRequests = 0;
      final remote = _cropRemote((request) async {
        if (request.method == 'POST') {
          createRequests += 1;
          expect(request.headers['Idempotency-Key'], requestId);
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          serverCrop ??= {
            ...body,
            'id': requestId,
            'userId': 'demo-farmer',
            'createdAt': '2026-08-06T12:00:00.000Z',
            'updatedAt': '2026-08-06T12:00:00.000Z',
          };
          if (createRequests == 1) {
            throw const SocketException('response lost after create');
          }
          return _response(serverCrop!);
        }
        return _response(serverCrop == null ? const [] : [serverCrop!]);
      });
      final local = LocalCropDataSource(preferences);
      final controller = await CropController.load(
        SyncedCropRepository(local, remote),
      );
      final tasks = CropTaskController.inMemory(
        cropController: controller,
        generateTasks: false,
      );
      final crop = Crop(
        id: requestId,
        userId: 'demo-farmer',
        kind: CropKind.mustard,
        variety: 'Pusa Bold',
        sowingDate: DateTime(2026, 8, 1),
        landArea: 1,
        landAreaUnit: LandAreaUnit.acre,
        growthStage: GrowthStage.vegetative,
        irrigationType: IrrigationType.manual,
      );

      expect(await controller.addCrop(crop), isTrue);
      expect(controller.crops, hasLength(1));
      expect(tasks.tasksForCrop(requestId), hasLength(4));

      await controller.refresh();
      expect(createRequests, 2);
      expect(controller.crops, hasLength(1));
      expect(controller.crops.single.id, requestId);
      expect(tasks.tasksForCrop(requestId), hasLength(4));

      final restored = await local.getCrops();
      expect(restored, hasLength(1));
      expect(restored.single.id, requestId);
    },
  );

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

  test(
    'crop update keeps submitted variety and health and persists after restart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      late Map<String, dynamic> updateBody;
      final remote = _cropRemote((request) async {
        if (request.method == 'PUT') {
          updateBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _response({
            ...updateBody,
            // A stale representation must not replace a successful edit.
            'variety': 'Old variety',
            'healthStatus': 'healthy',
            'id': 'crop-1',
            'userId': 'demo-farmer',
            'createdAt': '2026-07-01T00:00:00.000Z',
            'updatedAt': '2026-08-06T12:00:00.000Z',
          });
        }
        return _response(const []);
      });
      final local = LocalCropDataSource(preferences);
      await local.addCrop(
        CropModel(
          id: 'crop-1',
          userId: 'demo-farmer',
          cropType: 'tomato',
          variety: 'Old variety',
          sowingDate: DateTime(2026, 7),
          landArea: 1,
          landAreaUnit: 'acre',
          growthStage: 'vegetative',
          healthStatus: 'healthy',
          irrigationType: 'manual',
          soilType: 'loamy',
          plantingMethod: 'directSowing',
          createdAt: DateTime(2026, 7),
          updatedAt: DateTime(2026, 7),
        ),
      );
      final repository = SyncedCropRepository(local, remote);
      final updated = await repository.updateCrop(
        Crop(
          id: 'crop-1',
          userId: 'demo-farmer',
          kind: CropKind.tomato,
          variety: 'Arka Rakshak',
          sowingDate: DateTime(2026, 7),
          landArea: 1,
          landAreaUnit: LandAreaUnit.acre,
          growthStage: GrowthStage.vegetative,
          irrigationType: IrrigationType.manual,
          soilType: SoilType.loamy,
          plantingMethod: PlantingMethod.directSowing,
          health: CropHealth.needsAttention,
        ),
      );

      expect(updateBody['variety'], 'Arka Rakshak');
      expect(updateBody['healthStatus'], 'needsAttention');
      expect(updated.variety, 'Arka Rakshak');
      expect(updated.health, CropHealth.needsAttention);
      final restarted = await local.getCrops();
      expect(restarted.single.variety, 'Arka Rakshak');
      expect(restarted.single.healthStatus, 'needsAttention');
    },
  );
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
