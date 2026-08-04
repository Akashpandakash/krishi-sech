import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/features/my_crop/data/datasources/remote_crop_data_source.dart';
import 'package:krishi_sech/features/my_crop/data/models/crop_task_model.dart';

enum CropTaskRemoteFailureType { offline, unauthorized, server }

class CropTaskRemoteFailure implements Exception {
  const CropTaskRemoteFailure(this.type, [this.message]);
  final CropTaskRemoteFailureType type;
  final String? message;
}

class RemoteCropTaskDataSource {
  const RemoteCropTaskDataSource({
    required this.baseUrl,
    required this.accessTokenProvider,
    this.client,
  });

  final String baseUrl;
  final CropAccessTokenProvider accessTokenProvider;
  final http.Client? client;

  Future<List<CropTaskModel>> getTasks() async {
    final data = await _request('GET', '/api/calendar/tasks');
    if (data is! List<dynamic>) {
      throw const CropTaskRemoteFailure(CropTaskRemoteFailureType.server);
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(CropTaskModel.fromJson)
        .toList(growable: false);
  }

  Future<CropTaskModel> addTask(CropTaskModel task) async =>
      CropTaskModel.fromJson(
        await _mapRequest('POST', '/api/calendar/tasks', task.toApiJson()),
      );

  Future<CropTaskModel> updateTask(CropTaskModel task) async =>
      CropTaskModel.fromJson(
        await _mapRequest(
          'PUT',
          '/api/calendar/tasks/${Uri.encodeComponent(task.id)}',
          {...task.toApiJson()}..remove('id'),
        ),
      );

  Future<void> deleteTask(String id) async {
    await _request('DELETE', '/api/calendar/tasks/${Uri.encodeComponent(id)}');
  }

  Future<Map<String, dynamic>> _mapRequest(
    String method,
    String path,
    Map<String, dynamic> body,
  ) async {
    final data = await _request(method, path, body: body);
    if (data is! Map<String, dynamic>) {
      throw const CropTaskRemoteFailure(CropTaskRemoteFailureType.server);
    }
    return data;
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool retried = false,
  }) async {
    final token = await accessTokenProvider(forceRefresh: retried);
    if (token == null) {
      throw const CropTaskRemoteFailure(CropTaskRemoteFailureType.unauthorized);
    }
    final requestClient = client ?? http.Client();
    try {
      final request = http.Request(method, Uri.parse(baseUrl).resolve(path))
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (body != null) 'Content-Type': 'application/json',
        });
      if (body != null) request.body = jsonEncode(body);
      final response = await http.Response.fromStream(
        await requestClient
            .send(request)
            .timeout(AppEnvironment.requestTimeout),
      );
      if (response.statusCode == 401 && !retried) {
        return _request(method, path, body: body, retried: true);
      }
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CropTaskRemoteFailure(
          response.statusCode == 401
              ? CropTaskRemoteFailureType.unauthorized
              : CropTaskRemoteFailureType.server,
        );
      }
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw const CropTaskRemoteFailure(CropTaskRemoteFailureType.server);
      }
      return decoded['data'];
    } on SocketException {
      throw const CropTaskRemoteFailure(CropTaskRemoteFailureType.offline);
    } on TimeoutException {
      throw const CropTaskRemoteFailure(CropTaskRemoteFailureType.offline);
    } on http.ClientException {
      throw const CropTaskRemoteFailure(CropTaskRemoteFailureType.offline);
    } on FormatException {
      throw const CropTaskRemoteFailure(CropTaskRemoteFailureType.server);
    } finally {
      if (client == null) requestClient.close();
    }
  }
}
