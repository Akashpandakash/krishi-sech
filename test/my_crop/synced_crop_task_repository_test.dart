import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/local_crop_task_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/remote_crop_task_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/repositories/synced_crop_task_repository.dart';
import 'package:krishi_sech/features/my_crop/domain/entities/crop_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const baseUrl = 'http://127.0.0.1:3000';
  final now = DateTime.utc(2026, 8, 3, 10);

  CropTask task({String id = 'task-1'}) => CropTask(
    id: id,
    userId: 'user-1',
    cropId: 'crop-1',
    type: CropTaskReminderType.irrigation,
    dueDate: now.add(const Duration(days: 1)),
    notes: 'Check soil moisture',
    isGenerated: true,
    reminderTime: TaskReminderTime.oneHourBefore,
    notificationId: 42,
    createdAt: now,
    updatedAt: now,
  );

  Map<String, dynamic> apiTask(CropTask value) => {
    'id': value.id,
    'userId': 'user-1',
    'cropId': value.cropId,
    'taskType': value.type.name,
    'dueDate': value.dueDate.toUtc().toIso8601String(),
    'status': value.isCompleted ? 'completed' : 'pending',
    'notes': value.notes,
    'reminderEnabled': value.reminderTime != TaskReminderTime.none,
    'createdAt': value.createdAt.toUtc().toIso8601String(),
    'updatedAt': value.updatedAt.toUtc().toIso8601String(),
  };

  http.Response success(Object? data, [int status = 200]) => http.Response(
    jsonEncode({'success': true, 'data': data}),
    status,
    headers: {'content-type': 'application/json'},
  );

  Future<LocalCropTaskDataSource> localStore() async {
    final preferences = await SharedPreferences.getInstance();
    return LocalCropTaskDataSource(preferences);
  }

  RemoteCropTaskDataSource remote(http.Client client) =>
      RemoteCropTaskDataSource(
        baseUrl: baseUrl,
        accessTokenProvider: ({bool forceRefresh = false}) async =>
            'test-token',
        client: client,
      );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'uses authenticated calendar API and preserves reminder metadata',
    () async {
      final requests = <http.Request>[];
      final original = task();
      final client = MockClient((request) async {
        requests.add(request);
        expect(request.headers['authorization'], 'Bearer test-token');
        if (request.method == 'POST') return success(apiTask(original), 201);
        if (request.method == 'GET') return success([apiTask(original)]);
        if (request.method == 'PUT') {
          return success(apiTask(original.copyWith(isCompleted: true)));
        }
        if (request.method == 'DELETE') return success(null);
        return http.Response('', 500);
      });
      final repository = SyncedCropTaskRepository(
        await localStore(),
        remote(client),
      );

      final created = await repository.addTask(original);
      final listed = await repository.getTasks();
      final updated = await repository.updateTask(
        original.copyWith(isCompleted: true),
      );
      await repository.deleteTask(original.id);

      expect(created.reminderTime, TaskReminderTime.oneHourBefore);
      expect(created.notificationId, 42);
      expect(listed.single.reminderTime, TaskReminderTime.oneHourBefore);
      expect(updated.isCompleted, isTrue);
      expect(requests.map((request) => request.method), [
        'POST',
        'GET',
        'PUT',
        'DELETE',
      ]);
      expect(requests.last.url.path, '/api/calendar/tasks/task-1');
    },
  );

  test('caches offline changes and automatically syncs when online', () async {
    final local = await localStore();
    final offlineRepository = SyncedCropTaskRepository(
      local,
      remote(MockClient((_) async => throw const SocketException('offline'))),
    );
    final original = task(id: 'offline-task');

    await offlineRepository.addTask(original);
    expect((await local.getTasks()).single.id, original.id);
    expect((await local.getPendingOperations()).single.type, 'create');

    final methods = <String>[];
    final onlineRepository = SyncedCropTaskRepository(
      local,
      remote(
        MockClient((request) async {
          methods.add(request.method);
          if (request.method == 'POST') return success(apiTask(original), 201);
          if (request.method == 'GET') return success([apiTask(original)]);
          return http.Response('', 500);
        }),
      ),
    );

    final synced = await onlineRepository.getTasks();

    expect(methods, ['POST', 'GET']);
    expect(await local.getPendingOperations(), isEmpty);
    expect(synced.single.id, original.id);
    expect(synced.single.notificationId, 42);
  });
}
