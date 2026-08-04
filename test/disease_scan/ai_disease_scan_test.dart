import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:krishi_sech/features/disease_scan/data/datasources/local_disease_diagnosis_store.dart';
import 'package:krishi_sech/features/disease_scan/data/datasources/remote_disease_scan_data_source.dart';
import 'package:krishi_sech/features/disease_scan/data/repositories/remote_disease_scan_repository.dart';
import 'package:krishi_sech/features/disease_scan/domain/entities/disease_scan_failure.dart';
import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_request.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'uploads authenticated image, maps schema, and caches history',
    () async {
      final directory = await Directory.systemTemp.createTemp('disease-test-');
      addTearDown(() => directory.delete(recursive: true));
      final image = File('${directory.path}/leaf.jpg');
      await image.writeAsBytes(List<int>.filled(1024, 1));
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        expect(request.url.path, '/api/ai/disease-scan');
        expect(request.headers['authorization'], 'Bearer token');
        expect(
          request.headers['content-type'],
          contains('multipart/form-data'),
        );
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'scanId': 'scan-1',
              'crop': 'Rice',
              'disease': 'Leaf blast',
              'confidence': 0.88,
              'severity': 'medium',
              'symptoms': ['Spindle-shaped lesions'],
              'treatment': ['Remove affected leaves'],
              'medicine': ['Registered fungicide'],
              'organicAlternative': ['Neem formulation'],
              'prevention': ['Avoid excess nitrogen'],
              'expertConsultationRecommended': true,
              'createdAt': '2026-08-03T10:00:00.000Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final store = LocalDiseaseDiagnosisStore();
      final repository = RemoteDiseaseScanRepository(
        RemoteDiseaseScanDataSource(
          baseUrl: 'http://127.0.0.1:3000',
          accessTokenProvider: ({bool forceRefresh = false}) async => 'token',
          client: client,
        ),
        store,
      );

      final result = await repository.scan(
        DiseaseScanRequest(imagePath: image.path, language: 'en'),
      );

      expect(requests, 1);
      expect(result.cropName, 'Rice');
      expect(result.possibleDisease, 'Leaf blast');
      expect(result.medicine, ['Registered fungicide']);
      expect(result.organicAlternative, ['Neem formulation']);
      expect(result.prevention, ['Avoid excess nitrogen']);
      expect(result.needsExpertReview, isTrue);
      expect((await store.getLast())?.scanId, 'scan-1');
      expect(await store.getHistory(), hasLength(1));
    },
  );

  test('rejects images larger than 2 MB before network upload', () async {
    final directory = await Directory.systemTemp.createTemp('disease-limit-');
    addTearDown(() => directory.delete(recursive: true));
    final image = File('${directory.path}/large.jpg');
    await image.writeAsBytes(List<int>.filled(2 * 1024 * 1024 + 1, 0));
    var requests = 0;
    final source = RemoteDiseaseScanDataSource(
      baseUrl: 'http://127.0.0.1:3000',
      accessTokenProvider: ({bool forceRefresh = false}) async => 'token',
      client: MockClient((_) async {
        requests++;
        return http.Response('', 500);
      }),
    );

    await expectLater(
      source.scan(DiseaseScanRequest(imagePath: image.path)),
      throwsA(isA<DiseaseScanInvalidImageFailure>()),
    );
    expect(requests, 0);
  });

  test(
    'preserves exact backend OpenAI error instead of reporting timeout',
    () async {
      final directory = await Directory.systemTemp.createTemp('disease-error-');
      addTearDown(() => directory.delete(recursive: true));
      final image = File('${directory.path}/leaf.jpg');
      await image.writeAsBytes(List<int>.filled(128, 1));
      final source = RemoteDiseaseScanDataSource(
        baseUrl: 'http://127.0.0.1:3000',
        accessTokenProvider: ({bool forceRefresh = false}) async => 'token',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': false,
              'error': {
                'code': 'insufficient_quota',
                'message': 'You exceeded your current quota',
              },
            }),
            502,
          ),
        ),
      );

      await expectLater(
        source.scan(DiseaseScanRequest(imagePath: image.path)),
        throwsA(
          isA<DiseaseScanQuotaFailure>().having(
            (failure) => failure.message,
            'message',
            'You exceeded your current quota',
          ),
        ),
      );
    },
  );
}
