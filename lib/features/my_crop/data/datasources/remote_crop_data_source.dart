import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/features/my_crop/data/models/crop_model.dart';

enum CropRemoteFailureType { offline, unauthorized, notFound, server }

class CropRemoteFailure implements Exception {
  const CropRemoteFailure(this.type, [this.message]);
  final CropRemoteFailureType type;
  final String? message;
}

typedef CropAccessTokenProvider = Future<String?> Function({bool forceRefresh});

class RemoteCropDataSource {
  const RemoteCropDataSource({
    required this.baseUrl,
    required this.accessTokenProvider,
    this.client,
  });

  final String baseUrl;
  final CropAccessTokenProvider accessTokenProvider;
  final http.Client? client;

  Future<List<CropModel>> getCrops() async {
    final data = await _request('GET', '/api/crops');
    if (data is! List<dynamic>) {
      throw const CropRemoteFailure(CropRemoteFailureType.server);
    }
    try {
      return data
          .map((value) {
            if (value is! Map<String, dynamic>) {
              throw const FormatException('Invalid crop item');
            }
            return CropModel.fromJson(value);
          })
          .toList(growable: false);
    } on CropRemoteFailure {
      rethrow;
    } catch (_) {
      throw const CropRemoteFailure(CropRemoteFailureType.server);
    }
  }

  Future<CropModel> getCrop(String id) async =>
      CropModel.fromJson(await _mapRequest('GET', '/api/crops/$id', null));

  Future<CropModel> addCrop(CropModel crop) async => CropModel.fromJson(
    await _mapRequest(
      'POST',
      '/api/crops',
      crop.toApiJson(),
      idempotencyKey: _isUuid(crop.id) ? crop.id : null,
    ),
  );

  Future<CropModel> updateCrop(CropModel crop) async => CropModel.fromJson(
    await _mapRequest('PUT', '/api/crops/${crop.id}', crop.toApiJson()),
  );

  Future<void> deleteCrop(String id) async {
    await _request('DELETE', '/api/crops/$id');
  }

  Future<Map<String, dynamic>> _mapRequest(
    String method,
    String path,
    Map<String, dynamic>? body, {
    String? idempotencyKey,
  }) async {
    final data = await _request(
      method,
      path,
      body: body,
      idempotencyKey: idempotencyKey,
    );
    if (data is! Map<String, dynamic>) {
      throw const CropRemoteFailure(CropRemoteFailureType.server);
    }
    return data;
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool retried = false,
    String? idempotencyKey,
  }) async {
    final token = await accessTokenProvider(forceRefresh: retried);
    if (token == null) {
      throw const CropRemoteFailure(CropRemoteFailureType.unauthorized);
    }
    final requestClient = client ?? http.Client();
    try {
      final request = http.Request(method, Uri.parse(baseUrl).resolve(path))
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          if (body != null) 'Content-Type': 'application/json',
        });
      if (idempotencyKey != null) {
        request.headers['Idempotency-Key'] = idempotencyKey;
      }
      if (body != null) request.body = jsonEncode(body);
      final streamed = await requestClient
          .send(request)
          .timeout(AppEnvironment.requestTimeout);
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 401 && !retried) {
        return _request(
          method,
          path,
          body: body,
          retried: true,
          idempotencyKey: idempotencyKey,
        );
      }
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint(
            'Crop API $method $path failed with HTTP '
            '${response.statusCode}: ${_errorMessage(decoded) ?? 'Unknown error'} '
            '${_errorDetails(decoded)}',
          );
        }
        throw CropRemoteFailure(
          response.statusCode == 401
              ? CropRemoteFailureType.unauthorized
              : response.statusCode == 404
              ? CropRemoteFailureType.notFound
              : CropRemoteFailureType.server,
          _errorMessage(decoded),
        );
      }
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw const CropRemoteFailure(CropRemoteFailureType.server);
      }
      return decoded['data'];
    } on SocketException {
      throw const CropRemoteFailure(CropRemoteFailureType.offline);
    } on TimeoutException {
      throw const CropRemoteFailure(CropRemoteFailureType.offline);
    } on http.ClientException {
      throw const CropRemoteFailure(CropRemoteFailureType.offline);
    } on FormatException {
      throw const CropRemoteFailure(CropRemoteFailureType.server);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  String? _errorMessage(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final error = decoded['error'];
    return error is Map<String, dynamic> ? error['message'] as String? : null;
  }

  Object? _errorDetails(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final error = decoded['error'];
    return error is Map<String, dynamic> ? error['details'] : null;
  }

  bool _isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-'
    r'[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
