import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/core/notifications/notification_service.dart';
import 'package:krishi_sech/app/app.dart';
import 'package:krishi_sech/app/router/app_router.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/features/ai_assistant/data/repositories/local_ai_response_repository.dart';
import 'package:krishi_sech/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/ai_chat_scope.dart';
import 'package:krishi_sech/features/ai_assistant/presentation/controllers/ai_chat_controller.dart';
import 'package:krishi_sech/core/localization/locale_controller.dart';
import 'package:krishi_sech/core/localization/locale_scope.dart';
import 'package:krishi_sech/features/location/data/repositories/location_repository_impl.dart';
import 'package:krishi_sech/features/login/data/repositories/in_memory_auth_repository.dart';
import 'package:krishi_sech/features/login/presentation/auth_scope.dart';
import 'package:krishi_sech/features/login/presentation/controllers/auth_controller.dart';
import 'package:krishi_sech/features/location/data/services/location_service.dart';
import 'package:krishi_sech/features/location/domain/entities/farm_location.dart';
import 'package:krishi_sech/features/location/presentation/controllers/location_controller.dart';
import 'package:krishi_sech/features/location/presentation/location_scope.dart';
import 'package:krishi_sech/features/home/presentation/pages/home_page.dart';
import 'package:krishi_sech/features/weather/presentation/controllers/weather_controller.dart';
import 'package:krishi_sech/features/weather/presentation/weather_scope.dart';
import 'package:krishi_sech/features/weather/domain/entities/current_weather.dart';
import 'package:krishi_sech/features/weather/domain/repositories/weather_repository.dart';
import 'package:krishi_sech/features/location/domain/services/address_sanitizer.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_health_record_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_task_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/repositories/crop_repository_impl.dart';
import 'package:krishi_sech/features/my_crop/data/repositories/crop_health_record_repository_impl.dart';
import 'package:krishi_sech/features/my_crop/data/repositories/crop_task_repository_impl.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_health_record.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_repository.dart';
import 'package:krishi_sech/features/my_crop/domain/repositories/crop_task_repository.dart';
import 'package:krishi_sech/features/my_crop/domain/services/crop_task_rule_service.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_health_record_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/controllers/crop_task_controller.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_scope.dart';
import 'package:krishi_sech/features/my_crop/presentation/crop_task_scope.dart';
import 'package:krishi_sech/features/seasonal_advice/domain/entities/seasonal_advice.dart';
import 'package:krishi_sech/features/seasonal_advice/domain/services/seasonal_advice_service.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/controllers/seasonal_advice_controller.dart';
import 'package:krishi_sech/features/seasonal_advice/presentation/seasonal_advice_scope.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _openFirstOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(
    KrishiSechApp(
      localeController: LocaleController.inMemory(locale: const Locale('en')),
    ),
  );
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

class _LocalizedRouteApp extends StatelessWidget {
  const _LocalizedRouteApp({
    required this.initialRoute,
    required this.controller,
    this.locationController,
    this.weatherController,
    this.seasonalAdviceController,
    this.aiChatController,
    this.cropController,
    this.cropTaskController,
  });

  final String initialRoute;
  final LocaleController controller;
  final LocationController? locationController;
  final WeatherController? weatherController;
  final SeasonalAdviceController? seasonalAdviceController;
  final AiChatController? aiChatController;
  final CropController? cropController;
  final CropTaskController? cropTaskController;

  @override
  Widget build(BuildContext context) {
    final resolvedCropController = cropController ?? CropController.inMemory();
    final resolvedTaskController =
        cropTaskController ??
        CropTaskController.inMemory(cropController: resolvedCropController);
    return AuthScope(
      controller: AuthController(InMemoryAuthRepository()),
      child: LocationScope(
        controller: locationController ?? LocationController.inMemory(),
        child: WeatherScope(
          controller: weatherController ?? WeatherController.inMemory(),
          child: SeasonalAdviceScope(
            controller:
                seasonalAdviceController ?? SeasonalAdviceController.inMemory(),
            child: AiChatScope(
              controller:
                  aiChatController ??
                  AiChatController(
                    repository: const LocalAiResponseRepository(),
                    locationController:
                        locationController ?? LocationController.inMemory(),
                    weatherController:
                        weatherController ?? WeatherController.inMemory(),
                  ),
              child: CropScope(
                controller: resolvedCropController,
                child: CropTaskScope(
                  controller: resolvedTaskController,
                  child: LocaleScope(
                    controller: controller,
                    child: AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        return MaterialApp(
                          locale: controller.locale,
                          supportedLocales: AppLocalizations.supportedLocales,
                          localizationsDelegates: const [
                            AppLocalizations.delegate,
                            GlobalMaterialLocalizations.delegate,
                            GlobalWidgetsLocalizations.delegate,
                            GlobalCupertinoLocalizations.delegate,
                          ],
                          initialRoute: initialRoute,
                          onGenerateInitialRoutes: (route) => [
                            AppRouter.onGenerateRoute(
                              RouteSettings(name: route),
                            ),
                          ],
                          onGenerateRoute: AppRouter.onGenerateRoute,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FakeWeatherRepository implements WeatherRepository {
  int requests = 0;

  @override
  Future<CurrentWeather> fetchCurrentWeather(FarmLocation location) async {
    requests++;
    return CurrentWeather(
      temperatureCelsius: location.city == 'Kolkata' ? 31 : 28,
      weatherCode: 2,
      humidityPercent: 70,
      windSpeedKmh: 9,
    );
  }
}

class _LocationSheetTestApp extends StatelessWidget {
  const _LocationSheetTestApp({
    required this.controller,
    required this.environment,
  });

  final LocationController controller;
  final String environment;

  @override
  Widget build(BuildContext context) {
    return LocationScope(
      controller: controller,
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: LocationBottomSheet(environment: environment)),
      ),
    );
  }
}

class _CachedWeatherRepository implements WeatherSyncAwareRepository {
  @override
  bool get isUsingCachedData => true;

  @override
  Future<CurrentWeather> fetchCurrentWeather(FarmLocation location) async =>
      CurrentWeather(
        temperatureCelsius: 29,
        weatherCode: 2,
        humidityPercent: 88,
        windSpeedKmh: 11,
        rainProbabilityPercent: 70,
        updatedAt: DateTime(2026, 8, 4, 10, 30),
      );
}

class _ControlledCropRepository implements CropRepository {
  _ControlledCropRepository(this.crop);

  final Crop crop;
  final Completer<void> deleteCompleter = Completer<void>();
  int deleteCalls = 0;

  @override
  Future<Crop> addCrop(Crop crop) async => crop;

  @override
  Future<void> deleteCrop(String id) async {
    deleteCalls++;
    await deleteCompleter.future;
  }

  @override
  Future<List<Crop>> getCrops() async => [crop];

  @override
  Future<bool> hasUserCrops() async => true;

  @override
  Future<Crop> updateCrop(Crop crop) async => crop;
}

class _ControlledAddCropRepository implements CropRepository {
  final Completer<Crop> addCompleter = Completer<Crop>();
  int addCalls = 0;

  @override
  Future<Crop> addCrop(Crop crop) {
    addCalls++;
    return addCompleter.future;
  }

  @override
  Future<void> deleteCrop(String id) async {}

  @override
  Future<List<Crop>> getCrops() async => const [];

  @override
  Future<bool> hasUserCrops() async => false;

  @override
  Future<Crop> updateCrop(Crop crop) async => crop;
}

class _FailingCropRepository implements CropRepository {
  _FailingCropRepository(this.crop);

  final Crop crop;

  @override
  Future<Crop> addCrop(Crop crop) async => crop;

  @override
  Future<void> deleteCrop(String id) =>
      Future<void>.error(StateError('temporary delete failure'));

  @override
  Future<List<Crop>> getCrops() async => [crop];

  @override
  Future<bool> hasUserCrops() async => true;

  @override
  Future<Crop> updateCrop(Crop crop) async => crop;
}

class _EmptyThenHangingCropRepository implements CropRepository {
  int reads = 0;

  @override
  Future<Crop> addCrop(Crop crop) async => crop;

  @override
  Future<void> deleteCrop(String id) async {}

  @override
  Future<List<Crop>> getCrops() {
    reads++;
    if (reads == 1) return Future.value(const []);
    return Completer<List<Crop>>().future;
  }

  @override
  Future<bool> hasUserCrops() async => true;

  @override
  Future<Crop> updateCrop(Crop crop) async => crop;
}

class _HangingAfterFirstTaskRepository implements CropTaskRepository {
  int reads = 0;

  @override
  Future<CropTask> addTask(CropTask task) async => task;

  @override
  Future<void> deleteTask(String id) async {}

  @override
  Future<void> deleteTasksForCrop(String cropId) async {}

  @override
  Future<List<CropTask>> getTasks() {
    reads++;
    return reads == 1
        ? Future<List<CropTask>>.value(const [])
        : Completer<List<CropTask>>().future;
  }

  @override
  Future<CropTask> updateTask(CropTask task) async => task;
}

class _FakeNotificationService implements NotificationService {
  final List<int> scheduledIds = [];
  final List<int> cancelledIds = [];
  final List<DateTime> scheduledTimes = [];
  int permissionRequests = 0;

  @override
  Future<void> initialize({NotificationTapCallback? onTap}) async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String payload,
  }) async {
    scheduledIds.add(id);
    scheduledTimes.add(scheduledAt);
  }

  @override
  Future<void> cancel(int id) async => cancelledIds.add(id);
}

void main() {
  group('Crop Health Record', () {
    CropHealthRecord record({String title = 'Leaf spots'}) {
      final now = DateTime(2026, 8, 3);
      return CropHealthRecord(
        id: 'record-1',
        cropId: 'crop-1',
        type: CropHealthRecordType.disease,
        title: title,
        details: 'Observed on lower leaves',
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('adds, edits, deletes and restores records', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = CropHealthRecordRepositoryImpl(
        LocalCropHealthRecordDataSource(preferences),
      );
      final controller = await CropHealthRecordController.load(repository);

      await controller.addRecord(record());
      expect(controller.recordsForCrop('crop-1').single.title, 'Leaf spots');

      final restored = await CropHealthRecordController.load(repository);
      expect(restored.recordsForCrop('crop-1'), hasLength(1));

      await restored.updateRecord(record(title: 'Updated leaf spots'));
      expect(
        restored.recordsForCrop('crop-1').single.title,
        'Updated leaf spots',
      );

      await restored.deleteRecord('record-1');
      expect(restored.recordsForCrop('crop-1'), isEmpty);
      final afterRestart = await CropHealthRecordController.load(repository);
      expect(afterRestart.recordsForCrop('crop-1'), isEmpty);
    });
  });

  group('My Crops local feature', () {
    Crop testCrop({
      String id = 'crop-1',
      CropKind kind = CropKind.maize,
      CropHealth health = CropHealth.healthy,
      GrowthStage stage = GrowthStage.seedling,
      String variety = 'HQPM-1',
    }) => Crop(
      id: id,
      kind: kind,
      variety: variety,
      sowingDate: DateTime(2026, 7, 1),
      landArea: 2,
      landAreaUnit: LandAreaUnit.acre,
      growthStage: stage,
      irrigationType: IrrigationType.sprinkler,
      soilType: SoilType.loamy,
      plantingMethod: PlantingMethod.directSowing,
      seedBrand: 'Krishi Seeds',
      lastFertilizerUsed: 'Compost',
      lastPesticideUsed: 'Neem oil',
      health: health,
    );

    test('adds crop, removes samples and updates counts', () async {
      final controller = CropController.inMemory();
      await controller.addCrop(testCrop());
      expect(controller.crops, hasLength(1));
      expect(controller.crops.single.kind, CropKind.maize);
      expect(controller.totalCount, 1);
      expect(controller.healthyCount, 1);
      expect(controller.attentionCount, 0);
      expect(controller.upcomingTaskCount, 1);
    });

    test('repeated Add Crop submissions create exactly once', () async {
      final repository = _ControlledAddCropRepository();
      final controller = await CropController.load(repository);
      final crop = testCrop();

      final first = controller.addCrop(crop);
      final repeated = controller.addCrop(crop);
      expect(await repeated, isFalse);
      expect(repository.addCalls, 1);

      repository.addCompleter.complete(crop);
      expect(await first, isTrue);
      expect(controller.crops, hasLength(1));
    });

    test('edits crop and updates counts immediately', () async {
      final controller = CropController.inMemory(
        crops: [testCrop()],
        samples: false,
      );
      await controller.updateCrop(
        testCrop(
          variety: 'Updated variety',
          health: CropHealth.needsAttention,
          stage: GrowthStage.flowering,
        ),
      );
      expect(controller.crops.single.variety, 'Updated variety');
      expect(controller.crops.single.growthStage, GrowthStage.flowering);
      expect(controller.healthyCount, 0);
      expect(controller.attentionCount, 1);
    });

    testWidgets(
      'Edit Crop refreshes details and crop list with variety and health',
      (tester) async {
        final controller = CropController.inMemory(
          crops: [testCrop()],
          samples: false,
        );
        await tester.pumpWidget(
          _LocalizedRouteApp(
            initialRoute: AppRoutes.myCrop,
            controller: LocaleController.inMemory(locale: const Locale('en')),
            cropController: controller,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('crop_card_crop-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('edit_crop_action')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('crop_variety_field')),
          'HQPM-7',
        );
        final health = find.byType(DropdownButtonFormField<CropHealth>);
        await tester.ensureVisible(health);
        await tester.tap(health);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Needs Attention').last);
        await tester.pumpAndSettle();
        final save = find.byKey(const Key('save_crop_button'));
        await tester.ensureVisible(save);
        await tester.tap(save);
        await tester.pumpAndSettle();

        expect(find.text('Crop Details'), findsOneWidget);
        expect(find.text('HQPM-7'), findsOneWidget);
        expect(find.text('Needs Attention'), findsOneWidget);
        expect(controller.crops.single.variety, 'HQPM-7');
        expect(controller.crops.single.health, CropHealth.needsAttention);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.textContaining('HQPM-7'), findsOneWidget);
        expect(find.textContaining('Needs Attention'), findsOneWidget);
      },
    );

    test('deletes only the selected crop', () async {
      final controller = CropController.inMemory(
        crops: [
          testCrop(),
          testCrop(id: 'crop-2', kind: CropKind.potato),
        ],
        samples: false,
      );
      await controller.deleteCrop('crop-1');
      expect(controller.crops, hasLength(1));
      expect(controller.crops.single.id, 'crop-2');
    });

    test('duplicate crop deletion is blocked', () async {
      final repository = _ControlledCropRepository(testCrop());
      final controller = await CropController.load(repository);

      final first = controller.deleteCrop('crop-1');
      final second = controller.deleteCrop('crop-1');
      expect(await second, isFalse);
      expect(repository.deleteCalls, 1);

      repository.deleteCompleter.complete();
      expect(await first, isTrue);
      expect(controller.crops, isEmpty);
    });

    testWidgets(
      'Crop delete cancel preserves data and success cleans related tasks',
      (tester) async {
        final cropController = CropController.inMemory(
          crops: [
            testCrop(),
            testCrop(id: 'crop-2'),
          ],
          samples: false,
        );
        final now = DateTime.now();
        CropTask task(String id, String cropId) => CropTask(
          id: id,
          cropId: cropId,
          type: CropTaskReminderType.irrigation,
          dueDate: now,
          reminderTime: TaskReminderTime.none,
          createdAt: now,
          updatedAt: now,
        );
        final taskController = CropTaskController.inMemory(
          cropController: cropController,
          tasks: [task('related', 'crop-1'), task('unrelated', 'crop-2')],
          generateTasks: false,
        );
        await tester.pumpWidget(
          _LocalizedRouteApp(
            initialRoute: AppRoutes.myCrop,
            controller: LocaleController.inMemory(locale: const Locale('en')),
            cropController: cropController,
            cropTaskController: taskController,
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('crop_card_crop-1')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('delete_crop_action')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(cropController.totalCount, 2);
        expect(taskController.taskById('related'), isNotNull);

        await tester.tap(find.byKey(const Key('delete_crop_action')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('confirm_delete_crop')));
        await tester.pumpAndSettle();

        expect(find.text('My Crops'), findsWidgets);
        expect(cropController.totalCount, 1);
        expect(cropController.crops.single.id, 'crop-2');
        expect(taskController.taskById('related'), isNull);
        expect(taskController.taskById('unrelated'), isNotNull);

        await tester.tap(find.byKey(const Key('crop_calendar_button')));
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byKey(const Key('crop_task_calendar')), findsOneWidget);
        expect(taskController.taskById('unrelated'), isNotNull);
      },
    );

    testWidgets('failed Crop delete keeps data and shows retryable error', (
      tester,
    ) async {
      final controller = await CropController.load(
        _FailingCropRepository(testCrop()),
      );
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.myCrop,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          cropController: controller,
          cropTaskController: CropTaskController.inMemory(
            cropController: controller,
            generateTasks: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('crop_card_crop-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete_crop_action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_delete_crop')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('delete_crop_error')), findsOneWidget);
      expect(find.byKey(const Key('confirm_delete_crop')), findsOneWidget);
      expect(controller.crops.single.id, 'crop-1');
    });

    test('crop and related task deletion persist after restart', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final cropRepository = CropRepositoryImpl(
        LocalCropDataSource(preferences),
      );
      final taskRepository = CropTaskRepositoryImpl(
        LocalCropTaskDataSource(preferences),
      );
      final cropController = await CropController.load(cropRepository);
      await cropController.addCrop(testCrop());
      await cropController.addCrop(testCrop(id: 'crop-2'));
      final now = DateTime.now();
      final taskController = await CropTaskController.load(
        repository: taskRepository,
        cropController: cropController,
      );
      await taskController.addTask(
        CropTask(
          id: 'related-persisted',
          cropId: 'crop-1',
          type: CropTaskReminderType.irrigation,
          dueDate: now,
          reminderTime: TaskReminderTime.none,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await taskController.addTask(
        CropTask(
          id: 'unrelated-persisted',
          cropId: 'crop-2',
          type: CropTaskReminderType.fertilizer,
          dueDate: now,
          reminderTime: TaskReminderTime.none,
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(await cropController.deleteCrop('crop-1'), isTrue);
      await taskController.removeTasksForDeletedCrop('crop-1');

      final restartedCrops = await CropController.load(cropRepository);
      final restartedTasks = await CropTaskController.load(
        repository: taskRepository,
        cropController: restartedCrops,
      );
      expect(restartedCrops.crops.map((crop) => crop.id), ['crop-2']);
      expect(restartedTasks.taskById('related-persisted'), isNull);
      expect(restartedTasks.taskById('unrelated-persisted'), isNotNull);
    });

    test('persists and restores crops after restart', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = CropRepositoryImpl(LocalCropDataSource(preferences));
      final controller = await CropController.load(repository);
      await controller.addCrop(testCrop());

      final restored = await CropController.load(repository);
      expect(restored.crops, hasLength(1));
      expect(restored.crops.single.kind, CropKind.maize);
      expect(restored.crops.single.variety, 'HQPM-1');
      expect(restored.crops.single.landArea, 2);
      expect(restored.crops.single.soilType, SoilType.loamy);
      expect(restored.crops.single.plantingMethod, PlantingMethod.directSowing);
      expect(restored.crops.single.seedBrand, 'Krishi Seeds');
      expect(restored.crops.single.lastFertilizerUsed, 'Compost');
      expect(restored.crops.single.lastPesticideUsed, 'Neem oil');
    });

    testWidgets('add, restart, edit, Home update, delete and count lifecycle', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = CropRepositoryImpl(LocalCropDataSource(preferences));

      final firstSession = await CropController.load(repository);
      await firstSession.addCrop(testCrop());
      expect(firstSession.totalCount, 1);

      final reopenedSession = await CropController.load(repository);
      expect(reopenedSession.crops, hasLength(1));
      expect(reopenedSession.crops.single.variety, 'HQPM-1');

      await reopenedSession.updateCrop(
        testCrop(
          variety: 'Edited HQPM-1',
          stage: GrowthStage.flowering,
          health: CropHealth.needsAttention,
        ),
      );
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.home,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          cropController: reopenedSession,
        ),
      );
      expect(find.text('Flowering'), findsOneWidget);
      expect(find.text('Needs Attention'), findsOneWidget);

      await reopenedSession.deleteCrop('crop-1');
      await tester.pumpAndSettle();
      expect(reopenedSession.totalCount, 0);
      expect(reopenedSession.healthyCount, 0);
      expect(reopenedSession.attentionCount, 0);
      expect(find.text('Maize'), findsNothing);

      final afterDeleteRestart = await CropController.load(repository);
      expect(afterDeleteRestart.crops, isEmpty);
    });

    testWidgets('Add Crop shows localized validation', (tester) async {
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.addCrop,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          cropController: CropController.inMemory(samples: false),
        ),
      );
      final save = find.byKey(const Key('save_crop_button'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Please select a crop name.'), findsOneWidget);
      expect(find.text('Please select the sowing date.'), findsOneWidget);
      expect(find.text('Land area must be greater than zero.'), findsOneWidget);
    });

    testWidgets('Add Crop scrolls to final field and save above keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.addCrop,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          cropController: CropController.inMemory(samples: false),
        ),
      );
      await tester.pumpAndSettle();

      final scrollView = find.byKey(const Key('add_crop_scroll_view'));
      final notes = find.byKey(const Key('crop_notes_field'));
      final save = find.byKey(const Key('save_crop_button'));
      expect(scrollView, findsOneWidget);
      expect(save.hitTestable(), findsNothing);

      await tester.drag(scrollView, const Offset(0, -500));
      await tester.pumpAndSettle();
      final scrollable = tester.state<ScrollableState>(
        find
            .descendant(of: scrollView, matching: find.byType(Scrollable))
            .first,
      );
      expect(scrollable.position.pixels, greaterThan(0));

      await tester.ensureVisible(notes);
      await tester.pumpAndSettle();
      expect(notes.hitTestable(), findsOneWidget);
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);

      await tester.tap(notes);
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(save.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Home My Crops updates from the shared controller', (
      tester,
    ) async {
      final controller = CropController.inMemory(samples: false);
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.home,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          cropController: controller,
        ),
      );
      expect(find.text('Maize'), findsNothing);
      await controller.addCrop(testCrop());
      await tester.pumpAndSettle();
      expect(find.text('Maize'), findsOneWidget);
      expect(find.text('Seedling'), findsOneWidget);
    });

    testWidgets('crop labels update with app localization', (tester) async {
      final localeController = LocaleController.inMemory(
        locale: const Locale('en'),
      );
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.myCrop,
          controller: localeController,
          cropController: CropController.inMemory(
            crops: [testCrop(kind: CropKind.wheat)],
            samples: false,
          ),
        ),
      );
      expect(find.text('Wheat'), findsOneWidget);
      await localeController.setLocale(const Locale('bn'));
      await tester.pumpAndSettle();
      expect(find.text('গম'), findsOneWidget);
    });

    testWidgets('tapping a crop opens Crop Details', (tester) async {
      final crop = testCrop();
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.myCrop,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          cropController: CropController.inMemory(
            crops: [crop],
            samples: false,
          ),
        ),
      );
      await tester.tap(find.byKey(ValueKey('crop_card_${crop.id}')));
      await tester.pumpAndSettle();
      expect(find.text('Crop Details'), findsOneWidget);
      expect(find.text('HQPM-1'), findsOneWidget);
      expect(find.text('Crop Timeline'), findsOneWidget);
    });
  });

  group('Crop calendar and task reminders', () {
    Crop crop() => Crop(
      id: 'calendar-crop',
      kind: CropKind.wheat,
      variety: 'HD 2967',
      sowingDate: DateTime.now().subtract(const Duration(days: 10)),
      landArea: 1,
      landAreaUnit: LandAreaUnit.acre,
      growthStage: GrowthStage.seedling,
      irrigationType: IrrigationType.sprinkler,
    );

    test('generates irrigation, fertilizer, pest and harvest tasks', () {
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      final controller = CropTaskController.inMemory(
        cropController: cropController,
      );
      expect(controller.tasks, hasLength(4));
      expect(
        controller.tasks.map((task) => task.type).toSet(),
        CropTaskReminderType.values.toSet(),
      );
      expect(controller.tasks.every((task) => task.isGenerated), isTrue);
    });

    test('uses crop-specific sowing schedules and growth-stage task', () {
      const service = CropTaskRuleService();
      final generatedAt = DateTime(2026, 8, 3);
      final paddy = crop().copyWith(
        kind: CropKind.paddy,
        sowingDate: DateTime(2026, 8, 1),
        growthStage: GrowthStage.sowing,
      );
      final wheat = paddy.copyWith(kind: CropKind.wheat);
      final paddyTasks = service.generate(paddy, generatedAt: generatedAt);
      final wheatTasks = service.generate(wheat, generatedAt: generatedAt);
      final paddyIrrigation = paddyTasks.singleWhere(
        (task) => task.type == CropTaskReminderType.irrigation,
      );
      final wheatIrrigation = wheatTasks.singleWhere(
        (task) => task.type == CropTaskReminderType.irrigation,
      );
      expect(paddyIrrigation.dueDate, DateTime(2026, 8, 6, 7));
      expect(wheatIrrigation.dueDate, DateTime(2026, 8, 21, 7));
    });

    testWidgets('calendar loads real saved crops and not sample crops', (
      tester,
    ) async {
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.cropCalendar,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          cropController: cropController,
          cropTaskController: CropTaskController.inMemory(
            cropController: cropController,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('crop_task_calendar')), findsOneWidget);
      expect(find.byKey(const Key('add_crop_task_button')), findsOneWidget);
      expect(cropController.savedCrops.single.id, 'calendar-crop');
    });

    testWidgets('calendar shows empty state and opens existing Add Crop', (
      tester,
    ) async {
      final cropController = CropController.inMemory(samples: false);
      final taskController = CropTaskController.inMemory(
        cropController: cropController,
        generateTasks: false,
      );
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.cropCalendar,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          cropController: cropController,
          cropTaskController: taskController,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('crop_calendar_empty_state')),
        findsOneWidget,
      );
      expect(find.text('No crops added yet.'), findsOneWidget);

      await tester.tap(find.text('Add crop'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('save_crop_button')), findsOneWidget);

      await cropController.addCrop(crop());
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('crop_task_calendar')), findsOneWidget);
    });

    testWidgets(
      'zero crops opens calendar empty state before a refresh can hang',
      (tester) async {
        final repository = _EmptyThenHangingCropRepository();
        final cropController = await CropController.load(
          repository,
          operationTimeout: const Duration(milliseconds: 40),
        );
        final taskController = CropTaskController.inMemory(
          cropController: cropController,
          generateTasks: false,
        );

        await tester.pumpWidget(
          _LocalizedRouteApp(
            initialRoute: AppRoutes.cropCalendar,
            controller: LocaleController.inMemory(locale: const Locale('en')),
            cropController: cropController,
            cropTaskController: taskController,
          ),
        );
        await tester.pump();

        expect(
          find.byKey(const Key('crop_calendar_empty_state')),
          findsOneWidget,
        );
        expect(find.text('No crops added yet.'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump();
        expect(cropController.isLoading, isFalse);
        expect(cropController.error, isA<TimeoutException>());
        expect(find.text('Retry'), findsOneWidget);
      },
    );

    testWidgets('calendar shows a valid empty task state', (tester) async {
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.cropCalendar,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          cropController: cropController,
          cropTaskController: CropTaskController.inMemory(
            cropController: cropController,
            generateTasks: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No crop tasks scheduled'), findsOneWidget);
      expect(find.byKey(const Key('crop_task_calendar')), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('No tasks scheduled for this date.'), findsOneWidget);
    });

    testWidgets('calendar loading always resolves to a retryable error', (
      tester,
    ) async {
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      final repository = _HangingAfterFirstTaskRepository();
      final taskController = await CropTaskController.load(
        repository: repository,
        cropController: cropController,
        operationTimeout: const Duration(milliseconds: 30),
      );
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.cropCalendar,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          cropController: cropController,
          cropTaskController: taskController,
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(
        find.text('The crop calendar could not be loaded. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(taskController.isLoading, isFalse);
      expect(taskController.error, isA<TimeoutException>());
    });

    testWidgets('task crop dropdown contains saved crops and enables save', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      final taskController = CropTaskController.inMemory(
        cropController: cropController,
        generateTasks: false,
      );
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.cropCalendar,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          cropController: cropController,
          cropTaskController: taskController,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add_crop_task_button')));
      await tester.pumpAndSettle();

      var saveButton = tester.widget<FilledButton>(
        find.byKey(const Key('save_task_button')),
      );
      expect(saveButton.onPressed, isNull);
      final cropField = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const Key('task_crop_field')),
      );
      await tester.tap(find.byKey(const Key('task_crop_field')));
      await tester.pumpAndSettle();
      expect(find.text('Wheat').hitTestable(), findsOneWidget);
      await tester.tapAt(const Offset(790, 1190));
      await tester.pumpAndSettle();
      cropField.onChanged!('calendar-crop');
      await tester.pump();
      final typeField = tester
          .widget<DropdownButtonFormField<CropTaskReminderType>>(
            find.byKey(const Key('task_type_field')),
          );
      typeField.onChanged!(CropTaskReminderType.irrigation);
      await tester.pump();

      expect(find.text('Add Task'), findsOneWidget);
      expect(find.byKey(const Key('save_task_button')), findsOneWidget);
      saveButton = tester.widget<FilledButton>(
        find.byKey(const Key('save_task_button')),
      );
      expect(saveButton.onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('save_task_button')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('selected_date_tasks')),
          matching: find.text('Irrigation'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('date indicators and selection filter tasks correctly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      final now = DateTime.now();
      final firstDate = DateTime(now.year, now.month, now.day + 1);
      final secondDate = DateTime(now.year, now.month, now.day + 2);
      CropTask task(String id, DateTime date, CropTaskReminderType type) =>
          CropTask(
            id: id,
            cropId: crop().id,
            type: type,
            dueDate: date,
            createdAt: now,
            updatedAt: now,
          );
      final taskController = CropTaskController.inMemory(
        cropController: cropController,
        generateTasks: false,
        tasks: [
          task('first-date-task', firstDate, CropTaskReminderType.fertilizer),
          task('second-date-task', secondDate, CropTaskReminderType.harvest),
        ],
      );
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.cropCalendar,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          cropController: cropController,
          cropTaskController: taskController,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          ValueKey(
            'task_indicator_${firstDate.year}_${firstDate.month}_${firstDate.day}',
          ),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          ValueKey(
            'calendar_day_${secondDate.year}_${secondDate.month}_${secondDate.day}',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final selectedSection = find.byKey(const Key('selected_date_tasks'));
      expect(
        find.descendant(
          of: selectedSection,
          matching: find.byKey(const ValueKey('selected_second-date-task')),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: selectedSection,
          matching: find.byKey(const ValueKey('selected_first-date-task')),
        ),
        findsNothing,
      );
    });

    test('adds, edits, completes and deletes a task', () async {
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      final controller = CropTaskController.inMemory(
        cropController: cropController,
        generateTasks: false,
      );
      final now = DateTime.now();
      final task = CropTask(
        id: 'custom-task',
        cropId: crop().id,
        type: CropTaskReminderType.irrigation,
        dueDate: now,
        createdAt: now,
        updatedAt: now,
      );
      await controller.addTask(task);
      await controller.updateTask(
        task.copyWith(type: CropTaskReminderType.fertilizer),
      );
      expect(
        controller.taskById(task.id)!.type,
        CropTaskReminderType.fertilizer,
      );
      await controller.toggleCompleted(task.id);
      expect(controller.taskById(task.id)!.isCompleted, isTrue);
      await controller.deleteTask(task.id);
      expect(controller.tasks, isEmpty);
    });

    test('task creation schedules a future reminder', () async {
      final notifications = _FakeNotificationService();
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      final controller = CropTaskController.inMemory(
        cropController: cropController,
        generateTasks: false,
        notificationService: notifications,
      );
      final now = DateTime.now();
      await controller.addTask(
        CropTask(
          id: 'notification-create',
          cropId: crop().id,
          type: CropTaskReminderType.irrigation,
          dueDate: now.add(const Duration(hours: 2)),
          reminderTime: TaskReminderTime.thirtyMinutesBefore,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final saved = controller.taskById('notification-create')!;
      expect(saved.notificationId, isNotNull);
      expect(notifications.scheduledIds, [saved.notificationId]);
      expect(
        notifications.scheduledTimes.single,
        saved.dueDate.subtract(const Duration(minutes: 30)),
      );
    });

    test('editing a task cancels and reschedules its reminder', () async {
      final notifications = _FakeNotificationService();
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      final now = DateTime.now();
      final controller = CropTaskController.inMemory(
        cropController: cropController,
        generateTasks: false,
        notificationService: notifications,
      );
      await controller.addTask(
        CropTask(
          id: 'notification-edit',
          cropId: crop().id,
          type: CropTaskReminderType.fertilizer,
          dueDate: now.add(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
        ),
      );
      final original = controller.taskById('notification-edit')!;
      notifications.scheduledIds.clear();
      await controller.updateTask(
        original.copyWith(
          dueDate: now.add(const Duration(days: 3)),
          reminderTime: TaskReminderTime.oneHourBefore,
        ),
      );
      expect(notifications.cancelledIds, contains(original.notificationId));
      expect(notifications.scheduledIds, [original.notificationId]);
    });

    test('completing a task cancels its reminder', () async {
      final notifications = _FakeNotificationService();
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      final now = DateTime.now();
      final controller = CropTaskController.inMemory(
        cropController: cropController,
        generateTasks: false,
        notificationService: notifications,
      );
      await controller.addTask(
        CropTask(
          id: 'notification-complete',
          cropId: crop().id,
          type: CropTaskReminderType.harvest,
          dueDate: now.add(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
        ),
      );
      final id = controller.taskById('notification-complete')!.notificationId!;
      notifications.cancelledIds.clear();
      notifications.scheduledIds.clear();
      await controller.toggleCompleted('notification-complete');
      expect(notifications.cancelledIds, [id]);
      expect(notifications.scheduledIds, isEmpty);
    });

    test('deleting a task cancels its reminder', () async {
      final notifications = _FakeNotificationService();
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      final now = DateTime.now();
      final controller = CropTaskController.inMemory(
        cropController: cropController,
        generateTasks: false,
        notificationService: notifications,
      );
      await controller.addTask(
        CropTask(
          id: 'notification-delete',
          cropId: crop().id,
          type: CropTaskReminderType.pestInspection,
          dueDate: now.add(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
        ),
      );
      final id = controller.taskById('notification-delete')!.notificationId!;
      notifications.cancelledIds.clear();
      await controller.deleteTask('notification-delete');
      expect(notifications.cancelledIds, [id]);
    });

    test('no reminder creates no notification', () async {
      final notifications = _FakeNotificationService();
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      final now = DateTime.now();
      final controller = CropTaskController.inMemory(
        cropController: cropController,
        generateTasks: false,
        notificationService: notifications,
      );
      await controller.addTask(
        CropTask(
          id: 'notification-none',
          cropId: crop().id,
          type: CropTaskReminderType.irrigation,
          dueDate: now.add(const Duration(days: 2)),
          reminderTime: TaskReminderTime.none,
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect(notifications.scheduledIds, isEmpty);
      expect(notifications.permissionRequests, 0);
      expect(controller.taskById('notification-none')!.notificationId, isNull);
    });

    test('persists and restores tasks after restart', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final repository = CropTaskRepositoryImpl(
        LocalCropTaskDataSource(preferences),
      );
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      final first = await CropTaskController.load(
        repository: repository,
        cropController: cropController,
      );
      final deletedGeneratedId = first.tasks.first.id;
      await first.deleteTask(deletedGeneratedId);
      final now = DateTime.now();
      await first.addTask(
        CropTask(
          id: 'persisted-task',
          cropId: crop().id,
          type: CropTaskReminderType.pestInspection,
          dueDate: now.add(const Duration(days: 2)),
          notes: 'Inspect lower leaves',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final restored = await CropTaskController.load(
        repository: repository,
        cropController: cropController,
      );
      expect(
        restored.taskById('persisted-task')?.notes,
        'Inspect lower leaves',
      );
      expect(
        restored.tasks.any((task) => task.id == deletedGeneratedId),
        isFalse,
      );
    });

    testWidgets('calendar opens and Home shows repository task summary', (
      tester,
    ) async {
      final cropController = CropController.inMemory(
        crops: [crop()],
        samples: false,
      );
      final now = DateTime.now();
      final taskController = CropTaskController.inMemory(
        cropController: cropController,
        generateTasks: false,
        tasks: [
          CropTask(
            id: 'home-task',
            cropId: crop().id,
            type: CropTaskReminderType.fertilizer,
            dueDate: now,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.home,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          cropController: cropController,
          cropTaskController: taskController,
        ),
      );
      expect(find.text('Today’s Tasks'), findsOneWidget);
      expect(find.text('Fertilizer'), findsOneWidget);
      final viewCalendar = find.text('View Calendar');
      await tester.ensureVisible(viewCalendar);
      await tester.pumpAndSettle();
      await tester.tap(viewCalendar);
      await tester.pumpAndSettle();
      expect(find.text('Crop Calendar'), findsOneWidget);
      expect(find.byKey(const Key('crop_task_calendar')), findsOneWidget);
    });
  });

  group('local Krishi AI intent detection', () {
    const repository = LocalAiResponseRepository();

    Future<AiResponseType> responseFor(
      String question, {
      CurrentWeather? weather,
    }) => repository.generateResponse(question: question, weather: weather);

    test('detects Bengali language question', () async {
      expect(await responseFor('বাংলা জানো?'), AiResponseType.languageSupport);
    });

    test('detects transliterated Bengali wheat problem', () async {
      expect(
        await responseFor('amar gom er somossa'),
        AiResponseType.cropProblemWheat,
      );
    });

    test('detects Bengali-script wheat problem', () async {
      expect(
        await responseFor('আমার গমে সমস্যা'),
        AiResponseType.cropProblemWheat,
      );
    });

    test('detects English irrigation and uses rain context', () async {
      expect(
        await responseFor(
          'should I irrigate today?',
          weather: const CurrentWeather(
            temperatureCelsius: 28,
            weatherCode: 61,
            humidityPercent: 75,
            windSpeedKmh: 8,
            rainProbabilityPercent: 80,
          ),
        ),
        AiResponseType.irrigationDelayForRain,
      );
    });

    test('detects fertilizer question', () async {
      expect(
        await responseFor('which fertilizer should I use?'),
        AiResponseType.fertilizer,
      );
    });

    test('detects pest question', () async {
      expect(await responseFor('amar fasole poka ache'), AiResponseType.pests);
    });

    test('uses fallback only for an unknown question', () async {
      expect(
        await responseFor('tell me something unexpected'),
        AiResponseType.general,
      );
    });

    test('different questions return different responses', () async {
      final fertilizer = await responseFor('urea or dap fertilizer?');
      final pest = await responseFor('how do I control insects?');
      expect(fertilizer, isNot(pest));
    });

    test('detects Hindi-script wheat problem', () async {
      expect(
        await responseFor('गेहूं में समस्या'),
        AiResponseType.cropProblemWheat,
      );
    });
  });

  testWidgets('Home AI card opens the existing assistant', (tester) async {
    final locationController = LocationController.inMemory(
      location: const FarmLocation(
        city: 'Kolkata',
        district: 'Kolkata',
        state: 'West Bengal',
      ),
    );
    final weatherController = WeatherController.inMemory(
      weather: const CurrentWeather(
        temperatureCelsius: 29,
        weatherCode: 2,
        humidityPercent: 65,
        windSpeedKmh: 8,
      ),
    );
    final aiController = AiChatController(
      repository: const LocalAiResponseRepository(),
      locationController: locationController,
      weatherController: weatherController,
    );
    await tester.pumpWidget(
      _LocalizedRouteApp(
        initialRoute: AppRoutes.home,
        controller: LocaleController.inMemory(locale: const Locale('en')),
        locationController: locationController,
        weatherController: weatherController,
        aiChatController: aiController,
      ),
    );

    final aiCard = find.byKey(const Key('home_ai_assistant_card'));
    await tester.ensureVisible(aiCard);
    await tester.pumpAndSettle();
    await tester.tap(aiCard);
    await tester.pumpAndSettle();
    expect(find.text('Krishi AI Assistant'), findsOneWidget);
    expect(find.text('Your smart farming companion'), findsOneWidget);
    expect(find.byKey(const Key('ai_assistant_back')), findsOneWidget);
  });

  testWidgets(
    'AI chat submits text, blocks empty, uses suggestions and localizes',
    (tester) async {
      final localeController = LocaleController.inMemory(
        locale: const Locale('en'),
      );
      final locationController = LocationController.inMemory(
        location: const FarmLocation(
          city: 'Kolkata',
          district: 'Kolkata',
          state: 'West Bengal',
        ),
      );
      final weatherController = WeatherController.inMemory(
        weather: const CurrentWeather(
          temperatureCelsius: 29,
          weatherCode: 61,
          humidityPercent: 75,
          windSpeedKmh: 9,
          rainProbabilityPercent: 80,
        ),
      );
      final aiController = AiChatController(
        repository: const LocalAiResponseRepository(),
        locationController: locationController,
        weatherController: weatherController,
      );
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.aiAssistant,
          controller: localeController,
          locationController: locationController,
          weatherController: weatherController,
          aiChatController: aiController,
        ),
      );

      await tester.tap(find.byKey(const Key('ai_send_button')));
      await tester.pump();
      expect(aiController.messages, isEmpty);

      await tester.enterText(
        find.byKey(const Key('ai_question_field')),
        'Should I irrigate today?',
      );
      await tester.tap(find.byKey(const Key('ai_send_button')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(aiController.messages, hasLength(2));
      expect(
        find.text(
          'Rain is likely today, so delay irrigation and check soil moisture '
          'after the rain.',
        ),
        findsOneWidget,
      );

      aiController.newChat();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Will it rain today?'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(aiController.messages, hasLength(2));

      await localeController.setLocale(const Locale('bn'));
      await tester.pumpAndSettle();
      expect(find.text('আপনার স্মার্ট কৃষি সহায়ক'), findsOneWidget);
    },
  );

  group('seasonal advice rules', () {
    const service = SeasonalAdviceService();

    SeasonalAdvice adviceFor({
      double temperature = 28,
      int humidity = 60,
      double wind = 8,
      int rain = 10,
    }) {
      return service.generate(
        CurrentWeather(
          temperatureCelsius: temperature,
          weatherCode: 1,
          humidityPercent: humidity,
          windSpeedKmh: wind,
          rainProbabilityPercent: rain,
        ),
      );
    }

    test('generates rain advice', () {
      expect(adviceFor(rain: 70).type, SeasonalAdviceType.rain);
    });

    test('generates high humidity advice', () {
      expect(adviceFor(humidity: 90).type, SeasonalAdviceType.humidity);
    });

    test('generates high temperature advice', () {
      expect(adviceFor(temperature: 38).type, SeasonalAdviceType.heat);
    });

    test('generates high wind advice', () {
      expect(adviceFor(wind: 30).type, SeasonalAdviceType.wind);
    });

    test('generates normal weather advice', () {
      expect(adviceFor().type, SeasonalAdviceType.normal);
    });
  });

  testWidgets('Seasonal Advice card opens details', (tester) async {
    final locationController = LocationController.inMemory(
      location: const FarmLocation(
        city: 'Kolkata',
        district: 'Kolkata',
        state: 'West Bengal',
      ),
    );
    final weatherController = WeatherController.inMemory(
      weather: const CurrentWeather(
        temperatureCelsius: 29,
        weatherCode: 1,
        humidityPercent: 62,
        windSpeedKmh: 8,
        rainProbabilityPercent: 10,
      ),
    );
    final adviceController = SeasonalAdviceController(
      weatherController: weatherController,
      locationController: locationController,
    );
    await tester.pumpWidget(
      _LocalizedRouteApp(
        initialRoute: AppRoutes.home,
        controller: LocaleController.inMemory(locale: const Locale('en')),
        locationController: locationController,
        weatherController: weatherController,
        seasonalAdviceController: adviceController,
      ),
    );

    await tester.tap(find.byKey(const Key('seasonal_advice_card')));
    await tester.pumpAndSettle();
    expect(find.text('Seasonal Advice'), findsOneWidget);
    expect(find.text('Today’s recommendation'), findsOneWidget);
  });

  testWidgets('all Weather Card tap targets open Weather Details', (
    tester,
  ) async {
    Future<void> pumpWeatherHome() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        _LocalizedRouteApp(
          initialRoute: AppRoutes.home,
          controller: LocaleController.inMemory(locale: const Locale('en')),
          locationController: LocationController.inMemory(
            location: const FarmLocation(
              city: 'Kolkata',
              district: 'Kolkata',
              state: 'West Bengal',
            ),
          ),
          weatherController: WeatherController.inMemory(
            weather: CurrentWeather(
              temperatureCelsius: 29,
              weatherCode: 2,
              humidityPercent: 68,
              windSpeedKmh: 11,
              feelsLikeCelsius: 31,
              rainProbabilityPercent: 20,
              minimumTemperatureCelsius: 24,
              maximumTemperatureCelsius: 32,
              updatedAt: DateTime(2026, 8, 3, 10, 30),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpWeatherHome();
    await tester.tap(find.byKey(const Key('weather_temperature')));
    await tester.pumpAndSettle();
    expect(find.text('Weather Details'), findsOneWidget);

    await pumpWeatherHome();
    await tester.tap(find.byKey(const Key('weather_card_arrow')));
    await tester.pumpAndSettle();
    expect(find.text('Weather Details'), findsOneWidget);

    await pumpWeatherHome();
    await tester.tap(find.byKey(const Key('weather_card_empty_space')));
    await tester.pumpAndSettle();
    expect(find.text('Weather Details'), findsOneWidget);
  });

  testWidgets('cached Bangla weather fits a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final locationController = LocationController.inMemory(
      location: const FarmLocation(
        city: 'কলকাতা',
        district: 'কলকাতা জেলা',
        state: 'পশ্চিমবঙ্গ',
      ),
    );
    final weatherController = WeatherController(
      repository: _CachedWeatherRepository(),
      locationController: locationController,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: WeatherScope(
          controller: weatherController,
          child: const Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: 280, child: HomeWeatherCard()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weather_card')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    weatherController.dispose();
  });

  test('weather refreshes automatically when saved location changes', () async {
    final locationController = LocationController.inMemory(
      location: const FarmLocation(
        city: 'Jaipur',
        district: 'Jaipur',
        state: 'Rajasthan',
      ),
    );
    final repository = _FakeWeatherRepository();
    final weatherController = WeatherController(
      repository: repository,
      locationController: locationController,
    );
    await Future<void>.delayed(Duration.zero);

    expect(weatherController.weather?.temperatureCelsius, 28);
    await locationController.selectManualLocation(
      const FarmLocation(
        city: 'Kolkata',
        district: 'Kolkata',
        state: 'West Bengal',
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(repository.requests, 2);
    expect(weatherController.weather?.temperatureCelsius, 31);
    weatherController.dispose();
    locationController.dispose();
  });

  test('administrative divisions are removed from displayed addresses', () {
    expect(isAdministrativeDivisionName('Presidency Division'), isTrue);
    expect(isAdministrativeDivisionName('Revenue Division'), isTrue);
    expect(isAdministrativeDivisionName('Administrative Division'), isTrue);
    expect(
      firstFriendlyAddressPart([
        'Presidency Division',
        'Kolkata',
        'West Bengal',
      ]),
      'Kolkata',
    );
    expect(
      sanitizeFormattedAddress(
        'Kolkata, Presidency Division, West Bengal, India',
      ),
      'Kolkata, West Bengal, India',
    );
  });

  testWidgets('splash opens onboarding and Skip opens login', (tester) async {
    await _openFirstOnboarding(tester);

    expect(find.text('Smart Farming'), findsOneWidget);
    expect(find.text('Starts Here'), findsOneWidget);
    expect(find.text('KRISHI SECH'), findsNothing);

    await tester.tap(find.byKey(const Key('onboarding_skip')));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Krishi Sech'), findsOneWidget);
    expect(find.text('Smart Farming'), findsNothing);
  });

  testWidgets('complete onboarding and app navigation flow works', (
    tester,
  ) async {
    await _openFirstOnboarding(tester);

    await tester.tap(find.byKey(const Key('onboarding_next')));
    await tester.pumpAndSettle();

    expect(find.text('Your AI'), findsOneWidget);

    final secondNext = find.byKey(const Key('onboarding_second_next'));
    await tester.ensureVisible(secondNext);
    await tester.tap(secondNext);
    await tester.pumpAndSettle();

    final getStarted = find.byKey(const Key('onboarding_third_get_started'));
    await tester.ensureVisible(getStarted);
    await tester.tap(getStarted);
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Preferred Language'), findsOneWidget);
    final languageContinue = find.byKey(const Key('language_continue'));
    await tester.ensureVisible(languageContinue);
    await tester.tap(languageContinue);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '9876543210');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('otp_field')), '123456');
    await tester.tap(find.byKey(const Key('verify_otp_button')));
    await tester.pumpAndSettle();

    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('My Crops').last);
    await tester.pumpAndSettle();
    expect(find.text('Add crop'), findsOneWidget);

    await tester.tap(find.text('AI Assistant').last);
    await tester.pumpAndSettle();
    expect(find.text('Krishi AI Assistant'), findsOneWidget);

    await tester.tap(find.text('Market').last);
    await tester.pumpAndSettle();
    expect(find.text('Krishi Market'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Personal details'), findsOneWidget);

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    expect(find.text('Good morning,'), findsOneWidget);
  });

  testWidgets('onboarding screen 3 Back returns to screen 2', (tester) async {
    await tester.pumpWidget(
      _LocalizedRouteApp(
        initialRoute: AppRoutes.onboardingSecond,
        controller: LocaleController.inMemory(locale: const Locale('en')),
      ),
    );

    final context = tester.element(find.text('Your AI'));
    Navigator.of(context).pushNamed(AppRoutes.onboardingThird);
    await tester.pumpAndSettle();

    expect(find.text('Sell Smarter.'), findsOneWidget);
    final backButton = find.byKey(const Key('onboarding_third_back'));
    await tester.ensureVisible(backButton);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('Your AI'), findsOneWidget);
  });

  testWidgets('onboarding screen 3 opens language and Back returns', (
    tester,
  ) async {
    await tester.pumpWidget(
      _LocalizedRouteApp(
        initialRoute: AppRoutes.onboardingThird,
        controller: LocaleController.inMemory(locale: const Locale('en')),
      ),
    );

    final getStartedButton = find.byKey(
      const Key('onboarding_third_get_started'),
    );
    await tester.ensureVisible(getStartedButton);
    await tester.tap(getStartedButton);
    await tester.pumpAndSettle();
    expect(find.text('Choose Your Preferred Language'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Sell Smarter.'), findsOneWidget);
  });

  testWidgets('onboarding screen 2 Back opens screen 1', (tester) async {
    await tester.pumpWidget(
      _LocalizedRouteApp(
        initialRoute: AppRoutes.onboardingSecond,
        controller: LocaleController.inMemory(locale: const Locale('en')),
      ),
    );

    final backButton = find.byKey(const Key('onboarding_second_back'));
    await tester.ensureVisible(backButton);
    await tester.tap(backButton);
    await tester.pumpAndSettle();
    expect(find.text('Smart Farming'), findsOneWidget);
  });

  testWidgets('onboarding screen 2 Skip opens login', (tester) async {
    await tester.pumpWidget(
      _LocalizedRouteApp(
        initialRoute: AppRoutes.onboardingSecond,
        controller: LocaleController.inMemory(locale: const Locale('en')),
      ),
    );
    await tester.tap(find.byKey(const Key('onboarding_second_skip')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Krishi Sech'), findsOneWidget);
  });

  testWidgets('language selection defaults to Bangla and Skip opens login', (
    tester,
  ) async {
    await tester.pumpWidget(
      _LocalizedRouteApp(
        initialRoute: AppRoutes.languageSelection,
        controller: LocaleController.inMemory(),
      ),
    );

    expect(find.byKey(const Key('language_bn')), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('language_en')));
    await tester.tap(find.byKey(const Key('language_en')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);

    final languageSkip = find.byKey(const Key('language_skip'));
    await tester.ensureVisible(languageSkip);
    await tester.tap(languageSkip);
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Krishi Sech'), findsOneWidget);
  });

  testWidgets('bottom navigation updates English to Bangla to Hindi', (
    tester,
  ) async {
    final controller = LocaleController.inMemory(
      locale: const Locale('en'),
      hasSavedLocale: true,
    );
    await tester.pumpWidget(
      _LocalizedRouteApp(
        initialRoute: AppRoutes.home,
        controller: controller,
        locationController: LocationController.inMemory(
          location: const FarmLocation(
            state: 'Rajasthan',
            district: 'Jaipur',
            city: 'Jaipur',
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);

    await controller.setLocale(const Locale('bn'));
    await tester.pumpAndSettle();
    expect(find.text('হোম'), findsOneWidget);

    await controller.setLocale(const Locale('hi'));
    await tester.pumpAndSettle();
    expect(find.text('होम'), findsOneWidget);
  });

  testWidgets('saved locale skips onboarding on the next launch', (
    tester,
  ) async {
    await tester.pumpWidget(
      KrishiSechApp(
        localeController: LocaleController.inMemory(
          locale: const Locale('hi'),
          hasSavedLocale: true,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('कृषि सेच में आपका स्वागत है'), findsOneWidget);
    expect(find.text('स्मार्ट खेती'), findsNothing);
  });

  test('locale preference defaults, saves, and restores', () async {
    SharedPreferences.setMockInitialValues({});

    final initial = await LocaleController.load();
    expect(initial.locale.languageCode, 'bn');
    expect(initial.hasSavedLocale, isFalse);

    await initial.setLocale(const Locale('en'));
    await initial.setLocale(const Locale('bn'));
    await initial.setLocale(const Locale('hi'));

    final restored = await LocaleController.load();
    expect(restored.locale.languageCode, 'hi');
    expect(restored.hasSavedLocale, isTrue);
  });

  test('selected location is saved and restored', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = LocationRepositoryImpl(
      preferences: preferences,
      locationService: const LocationService(),
    );
    final selectedLocation = FarmLocation(
      country: 'India',
      state: 'Rajasthan',
      district: 'Jaipur',
      city: 'Chomu',
      village: 'Kaladera',
      postalCode: '303801',
      accuracyMeters: 12.5,
      latitude: 27.1667,
      longitude: 75.7167,
      gpsTimestamp: DateTime.utc(2026, 8, 2, 10, 30),
      detectedLocality: 'Chomu',
      fullAddress: 'Chomu, Jaipur, Rajasthan 303801, India',
    );

    await repository.saveLocation(selectedLocation);
    final restored = await repository.loadSavedLocation();

    expect(restored?.country, 'India');
    expect(restored?.state, 'Rajasthan');
    expect(restored?.district, 'Jaipur');
    expect(restored?.city, 'Chomu');
    expect(restored?.village, 'Kaladera');
    expect(restored?.postalCode, '303801');
    expect(restored?.accuracyMeters, 12.5);
    expect(restored?.latitude, 27.1667);
    expect(restored?.longitude, 75.7167);
    expect(restored?.gpsTimestamp, DateTime.utc(2026, 8, 2, 10, 30));
    expect(restored?.detectedLocality, 'Chomu');
    expect(restored?.fullAddress, 'Chomu, Jaipur, Rajasthan 303801, India');
  });

  testWidgets('Home location sheet opens and manual save updates Home', (
    tester,
  ) async {
    final locationController = LocationController.inMemory(
      location: const FarmLocation(
        state: 'Rajasthan',
        district: 'Jaipur',
        city: 'Jaipur',
      ),
    );
    await tester.pumpWidget(
      _LocalizedRouteApp(
        initialRoute: AppRoutes.home,
        controller: LocaleController.inMemory(locale: const Locale('en')),
        locationController: locationController,
      ),
    );

    await tester.tap(find.byKey(const Key('home_location_area')));
    await tester.pumpAndSettle();

    expect(find.text('Your Location'), findsOneWidget);
    expect(find.text('Using your saved location'), findsOneWidget);

    await tester.tap(find.byKey(const Key('add_change_location')));
    await tester.pumpAndSettle();

    expect(find.text('Select Location'), findsOneWidget);
    expect(find.byKey(const Key('manual_location_search')), findsOneWidget);
    expect(
      find.byKey(const Key('manual_use_current_location')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('manual_location_search')),
      'Chomu',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('location_suggestion_Chomu')));
    await tester.pumpAndSettle();
    final saveButton = find.byKey(const Key('manual_save_location'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(
      locationController.location?.displayName,
      'Chomu, Jaipur, Rajasthan',
    );
    expect(find.text('Chomu, Jaipur, Rajasthan'), findsOneWidget);
    expect(find.text('Your Location'), findsNothing);
  });

  for (final environment in const ['development', 'staging', 'production']) {
    testWidgets(
      'location debug section ${environment == 'development' ? 'is visible' : 'is hidden'} in $environment',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final locationController = LocationController.inMemory(
          location: FarmLocation(
            state: 'West Bengal',
            district: 'Kolkata',
            city: 'Kolkata',
            latitude: 22.5726,
            longitude: 88.3639,
            accuracyMeters: 18,
            gpsTimestamp: DateTime.utc(2026, 8, 6, 8),
          ),
        );
        await tester.pumpWidget(
          _LocationSheetTestApp(
            controller: locationController,
            environment: environment,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Your Location'), findsOneWidget);
        expect(find.text('Kolkata'), findsWidgets);
        expect(find.text('West Bengal'), findsOneWidget);
        expect(
          find.byKey(const Key('refresh_current_location')),
          findsOneWidget,
        );
        expect(
          find.text('Location debug'),
          environment == 'development' ? findsOneWidget : findsNothing,
        );
      },
    );
  }

  testWidgets('routes with missing arguments fail safely', (tester) async {
    await tester.pumpWidget(
      _LocalizedRouteApp(
        initialRoute: AppRoutes.otp,
        controller: LocaleController.inMemory(locale: const Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
