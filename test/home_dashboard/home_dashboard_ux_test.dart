import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:krishi_sech/features/disease_scan/data/datasources/local_disease_diagnosis_store.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/smart_dashboard/data/datasources/remote_smart_recommendation_data_source.dart';
import 'package:krishi_sech/features/smart_dashboard/data/datasources/smart_recommendation_cache.dart';
import 'package:krishi_sech/features/smart_dashboard/data/repositories/smart_recommendation_repository.dart';
import 'package:krishi_sech/features/smart_dashboard/domain/entities/smart_recommendation_snapshot.dart';
import 'package:krishi_sech/features/smart_dashboard/presentation/controllers/smart_recommendation_controller.dart';
import 'package:krishi_sech/features/smart_dashboard/presentation/widgets/smart_farming_dashboard.dart';
import 'package:krishi_sech/features/weather/data/datasources/local_weather_data_source.dart';
import 'package:krishi_sech/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:krishi_sech/features/weather/data/services/weather_service.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const location = FarmLocation(
    city: 'Kolkata',
    district: 'Kolkata',
    state: 'West Bengal',
    country: 'India',
    latitude: 22.57,
    longitude: 88.36,
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('live weather response is parsed and cached', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = WeatherRepositoryImpl(
      WeatherService(
        baseUrl: 'http://weather.test',
        languageProvider: () => 'en',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'temperatureCelsius': 28.3,
                'weatherCode': 3,
                'humidityPercent': 93,
                'windSpeedKmh': 4.8,
                'rainProbabilityPercent': 95,
                'updatedAt': '2026-08-04T10:00:00Z',
              },
            }),
            200,
          ),
        ),
      ),
      LocalWeatherDataSource(preferences),
    );
    final weather = await repository.fetchCurrentWeather(location);
    expect(weather.temperatureCelsius, 28.3);
    expect(
      (await LocalWeatherDataSource(
        preferences,
      ).read(location))?.temperatureCelsius,
      28.3,
    );
  });

  test('cached weather is returned when offline', () async {
    final preferences = await SharedPreferences.getInstance();
    const cached = CurrentWeather(
      temperatureCelsius: 27,
      weatherCode: 2,
      humidityPercent: 70,
      windSpeedKmh: 6,
    );
    await LocalWeatherDataSource(preferences).save(location, cached);
    final repository = WeatherRepositoryImpl(
      WeatherService(
        baseUrl: 'http://weather.test',
        languageProvider: () => 'en',
        client: MockClient((_) async => throw http.ClientException('offline')),
      ),
      LocalWeatherDataSource(preferences),
    );
    expect(
      (await repository.fetchCurrentWeather(location)).temperatureCelsius,
      27,
    );
    expect(repository.isUsingCachedData, isTrue);
  });

  test('partial recommendation failure preserves successful card', () async {
    final source = RemoteSmartRecommendationDataSource(
      baseUrl: 'http://api.test',
      accessTokenProvider: ({bool forceRefresh = false}) async => 'token',
      client: MockClient((request) async {
        if (request.url.path.contains('irrigation')) {
          return http.Response('{}', 503);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'recommendedFertilizer': 'Urea',
              'quantity': {'value': 20, 'unit': 'kg', 'per': 'acre'},
              'nextRecommendationDate': '2026-08-10T00:00:00Z',
              'confidence': 0.8,
            },
          }),
          200,
        );
      }),
    );
    final result = await source.fetch(language: 'en');
    expect(result.irrigation, isNull);
    expect(result.irrigationFailed, isTrue);
    expect(result.fertilizer?.name, 'Urea');
  });

  testWidgets('small screen and Bangla text render without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = SmartRecommendationController(_ImmediateRepository())
      ..snapshot = _snapshot;
    await tester.pumpWidget(_localizedApp(controller, const Locale('bn')));
    await tester.pumpAndSettle();
    expect(find.text('আজকের স্মার্ট কৃষি'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pull refresh does not start a duplicate recommendation request',
    (tester) async {
      final repository = _SlowRepository();
      final controller = SmartRecommendationController(repository)
        ..snapshot = _snapshot;
      await tester.pumpWidget(
        _localizedApp(controller, const Locale('en'), refreshable: true),
      );
      await tester.drag(find.byType(ListView), const Offset(0, 350));
      await tester.pump();
      controller.refresh('en');
      expect(repository.calls, 1);
      repository.complete();
      await tester.pumpAndSettle();
    },
  );
}

final _snapshot = SmartRecommendationSnapshot(
  irrigation: IrrigationSummary(
    required: false,
    quantityLiters: 0,
    method: 'Drip',
    nextDate: DateTime(2026, 8, 10),
    confidence: 0.8,
  ),
  fertilizer: FertilizerSummary(
    name: 'Urea',
    quantity: '20 kg/acre',
    nextDate: DateTime(2026, 8, 10),
    confidence: 0.8,
  ),
);

Widget _localizedApp(
  SmartRecommendationController controller,
  Locale locale, {
  bool refreshable = false,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: refreshable
        ? RefreshIndicator(
            onRefresh: () => controller.refresh(locale.languageCode),
            child: ListView(
              children: [
                SmartFarmingDashboard(
                  controller: controller,
                  weather: null,
                  tasks: const [],
                  currentCrop: null,
                ),
                const SizedBox(height: 800),
              ],
            ),
          )
        : SingleChildScrollView(
            child: SmartFarmingDashboard(
              controller: controller,
              weather: null,
              tasks: const [],
              currentCrop: null,
            ),
          ),
  ),
);

class _ImmediateRepository extends SmartRecommendationRepository {
  _ImmediateRepository()
    : super(
        _dummyRemote,
        SmartRecommendationCache(),
        LocalDiseaseDiagnosisStore(),
      );
  @override
  Future<SmartRecommendationSnapshot> load(String language) async => _snapshot;
}

class _SlowRepository extends SmartRecommendationRepository {
  _SlowRepository()
    : super(
        _dummyRemote,
        SmartRecommendationCache(),
        LocalDiseaseDiagnosisStore(),
      );
  final completer = Completer<SmartRecommendationSnapshot>();
  int calls = 0;
  @override
  Future<SmartRecommendationSnapshot> load(String language) {
    calls++;
    return completer.future;
  }

  void complete() => completer.complete(_snapshot);
}

final _dummyRemote = RemoteSmartRecommendationDataSource(
  baseUrl: 'http://unused',
  accessTokenProvider: ({bool forceRefresh = false}) async => null,
);
