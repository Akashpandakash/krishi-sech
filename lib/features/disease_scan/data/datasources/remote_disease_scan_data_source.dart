import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_request.dart';
import 'package:krishi_sech/features/disease_scan/domain/models/disease_scan_result.dart';
import 'package:krishi_sech/features/disease_scan/domain/entities/disease_scan_failure.dart';
import 'package:krishi_sech/core/config/app_environment.dart';

typedef DiseaseAccessTokenProvider =
    Future<String?> Function({bool forceRefresh});

class RemoteDiseaseScanDataSource {
  const RemoteDiseaseScanDataSource({
    required this.baseUrl,
    required this.accessTokenProvider,
    this.client,
  });

  final String baseUrl;
  final http.Client? client;
  final DiseaseAccessTokenProvider accessTokenProvider;

  Future<DiseaseScanResult> scan(DiseaseScanRequest request) async {
    return _scan(request);
  }

  Future<DiseaseScanResult> _scan(
    DiseaseScanRequest request, {
    bool retried = false,
  }) async {
    final uri = Uri.parse(baseUrl).resolve('/api/ai/disease-scan');
    final image = File(request.imagePath);
    if (!await image.exists()) {
      throw const DiseaseScanInvalidImageFailure(
        'Selected image was not found',
      );
    }
    final imageLength = await image.length();
    if (imageLength == 0 || imageLength > 2 * 1024 * 1024) {
      throw const DiseaseScanInvalidImageFailure(
        'Compressed image must be between 1 byte and 2 MB',
      );
    }
    final token = await accessTokenProvider(forceRefresh: retried);
    if (token == null) throw const DiseaseScanAuthenticationFailure();
    final totalStarted = Stopwatch()..start();
    int? uploadTimeMs;
    final multipart = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields.addAll(request.toFields())
      ..files.add(
        http.MultipartFile(
          'image',
          _progressStream(image, imageLength, request.onUploadProgress, () {
            uploadTimeMs = totalStarted.elapsedMilliseconds;
            _log('✓ step=3 image uploaded uploadTimeMs=$uploadTimeMs');
          }),
          imageLength,
          filename: Uri.file(request.imagePath).pathSegments.last,
        ),
      );
    _log(
      '✓ step=3 multipart upload started url=$uri compressedBytes=$imageLength',
    );

    final requestClient = client ?? http.Client();
    try {
      final streamed = await requestClient
          .send(multipart)
          .timeout(const Duration(seconds: 65));
      final response = await http.Response.fromStream(
        streamed,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 401 && !retried) {
        return _scan(request, retried: true);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = _errorDetails(response.body);
        final message = error.message;
        _log(
          '✗ step=10 Flutter received error status=${response.statusCode} code=${error.code ?? 'unknown'} '
          'uploadTimeMs=${uploadTimeMs ?? -1} totalMs=${totalStarted.elapsedMilliseconds} '
          'reason=${message ?? 'unknown'}',
        );
        if (error.code == 'insufficient_quota') {
          throw DiseaseScanQuotaFailure(message);
        }
        if (error.code == 'IMAGE_TOO_LARGE' ||
            error.code == 'INVALID_IMAGE_TYPE' ||
            error.code == 'IMAGE_REQUIRED') {
          throw DiseaseScanInvalidImageFailure(message);
        }
        if (response.statusCode == 401 || response.statusCode == 403) {
          throw DiseaseScanAuthenticationFailure(message);
        }
        throw DiseaseScanServerFailure(response.statusCode, message);
      }
      _log(
        '✓ step=10 Flutter received response status=${response.statusCode} '
        'uploadTimeMs=${uploadTimeMs ?? -1} totalMs=${totalStarted.elapsedMilliseconds}',
      );
      final parseStarted = Stopwatch()..start();
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic> || payload['success'] != true) {
        throw const DiseaseScanInvalidResponseFailure();
      }
      try {
        final data = payload['data'];
        if (data is! Map<String, dynamic>) {
          throw const DiseaseScanInvalidResponseFailure();
        }
        final result = DiseaseScanResult.fromJson(data);
        _log(
          '✓ step=9 structured JSON parsed jsonParsingMs=${parseStarted.elapsedMilliseconds}',
        );
        return result;
      } on FormatException {
        throw const DiseaseScanInvalidResponseFailure();
      }
    } on FormatException {
      throw const DiseaseScanInvalidResponseFailure();
    } on SocketException {
      throw const DiseaseScanOfflineFailure();
    } on TimeoutException {
      final message = 'Request exceeded the Vision response deadline';
      _log(
        '✗ step=10 Flutter request timeout totalMs=${totalStarted.elapsedMilliseconds} reason=$message',
      );
      throw DiseaseScanTimeoutFailure(message);
    } on http.ClientException {
      throw const DiseaseScanOfflineFailure();
    } finally {
      if (client == null) requestClient.close();
    }
  }

  Stream<List<int>> _progressStream(
    File image,
    int totalBytes,
    void Function(double progress)? onProgress,
    VoidCallback onComplete,
  ) async* {
    var sentBytes = 0;
    onProgress?.call(0);
    await for (final chunk in image.openRead()) {
      sentBytes += chunk.length;
      onProgress?.call(totalBytes == 0 ? 1 : sentBytes / totalBytes);
      yield chunk;
    }
    onComplete();
  }

  ({String? code, String? message}) _errorDetails(String body) {
    try {
      final decoded = jsonDecode(body);
      final error = decoded is Map<String, dynamic> ? decoded['error'] : null;
      return (
        code: error is Map<String, dynamic> ? error['code'] as String? : null,
        message: error is Map<String, dynamic>
            ? error['message'] as String?
            : null,
      );
    } catch (_) {
      return (code: null, message: null);
    }
  }

  void _log(String message) {
    if (kDebugMode && AppEnvironment.loggingEnabled) {
      debugPrint('[AI Vision] $message');
    }
  }
}
