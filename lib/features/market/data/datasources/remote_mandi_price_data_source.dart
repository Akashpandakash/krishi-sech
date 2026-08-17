import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/features/market/data/models/mandi_price_model.dart';
import 'package:krishi_sech/features/market/domain/entities/mandi_price.dart';

enum MandiRemoteFailureType {
  offline,
  unauthorized,
  /// The backend has no data.gov.in API key configured.
  notConfigured,
  /// The upstream AGMARKNET feed failed or timed out.
  upstream,
  server,
}

class MandiRemoteFailure implements Exception {
  const MandiRemoteFailure(this.type, [this.message]);
  final MandiRemoteFailureType type;
  final String? message;
}

typedef MandiAccessTokenProvider = Future<String?> Function({
  bool forceRefresh,
});

class RemoteMandiPriceDataSource {
  const RemoteMandiPriceDataSource({
    required this.baseUrl,
    required this.accessTokenProvider,
    this.client,
  });

  final String baseUrl;
  final MandiAccessTokenProvider accessTokenProvider;
  final http.Client? client;

  Future<MandiPriceBoard> getPrices({
    required String state,
    String? district,
    String? commodity,
  }) async {
    final data = await _request({
      'state': state,
      if (district != null && district.trim().isNotEmpty) 'district': district,
      if (commodity != null && commodity.trim().isNotEmpty)
        'commodity': commodity,
    });
    final prices = data['prices'];
    if (prices is! List<dynamic>) {
      throw const MandiRemoteFailure(MandiRemoteFailureType.server);
    }
    try {
      return MandiPriceBoard(
        prices: prices
            .map(
              (value) =>
                  MandiPriceMapper.fromJson(value as Map<String, dynamic>),
            )
            .toList(growable: false),
        // Absent means an older backend that only ever served the live feed;
        // treating that as live matches what it actually returned.
        isLive: data['live'] as bool? ?? true,
      );
    } catch (_) {
      throw const MandiRemoteFailure(MandiRemoteFailureType.server);
    }
  }

  Future<Map<String, dynamic>> _request(
    Map<String, String> query, {
    bool retried = false,
  }) async {
    final token = await accessTokenProvider(forceRefresh: retried);
    if (token == null) {
      throw const MandiRemoteFailure(MandiRemoteFailureType.unauthorized);
    }
    final requestClient = client ?? http.Client();
    try {
      final uri = Uri.parse(
        baseUrl,
      ).resolve('/api/mandi/prices').replace(queryParameters: query);
      final response = await requestClient
          .get(uri, headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          })
          .timeout(AppEnvironment.requestTimeout);
      if (response.statusCode == 401 && !retried) {
        return _request(query, retried: true);
      }
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint(
            'Mandi API failed with HTTP ${response.statusCode}: '
            '${_errorMessage(decoded) ?? 'Unknown error'}',
          );
        }
        throw MandiRemoteFailure(
          _failureType(response.statusCode, _errorCode(decoded)),
          _errorMessage(decoded),
        );
      }
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw const MandiRemoteFailure(MandiRemoteFailureType.server);
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw const MandiRemoteFailure(MandiRemoteFailureType.server);
      }
      return data;
    } on SocketException {
      throw const MandiRemoteFailure(MandiRemoteFailureType.offline);
    } on TimeoutException {
      throw const MandiRemoteFailure(MandiRemoteFailureType.offline);
    } on http.ClientException {
      throw const MandiRemoteFailure(MandiRemoteFailureType.offline);
    } on FormatException {
      throw const MandiRemoteFailure(MandiRemoteFailureType.server);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  MandiRemoteFailureType _failureType(int statusCode, String? code) {
    if (statusCode == 401) return MandiRemoteFailureType.unauthorized;
    if (code == 'MANDI_NOT_CONFIGURED') {
      return MandiRemoteFailureType.notConfigured;
    }
    // 502/504 mean data.gov.in is the problem, not us — worth telling the
    // farmer apart from a bug so a retry later reads as sensible.
    if (statusCode == 502 || statusCode == 504) {
      return MandiRemoteFailureType.upstream;
    }
    return MandiRemoteFailureType.server;
  }

  String? _errorMessage(Object? decoded) {
    final error = _error(decoded);
    return error == null ? null : error['message'] as String?;
  }

  String? _errorCode(Object? decoded) {
    final error = _error(decoded);
    return error == null ? null : error['code'] as String?;
  }

  Map<String, dynamic>? _error(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final error = decoded['error'];
    return error is Map<String, dynamic> ? error : null;
  }
}
