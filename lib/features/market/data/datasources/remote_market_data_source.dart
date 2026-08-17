import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/features/market/data/models/market_product_model.dart';
import 'package:krishi_sech/features/market/domain/entities/market_product.dart';

enum MarketRemoteFailureType { offline, unauthorized, notFound, server }

class MarketRemoteFailure implements Exception {
  const MarketRemoteFailure(this.type, [this.message]);
  final MarketRemoteFailureType type;
  final String? message;
}

typedef MarketAccessTokenProvider = Future<String?> Function({
  bool forceRefresh,
});

class RemoteMarketDataSource {
  const RemoteMarketDataSource({
    required this.baseUrl,
    required this.accessTokenProvider,
    this.languageProvider,
    this.client,
  });

  final String baseUrl;
  final MarketAccessTokenProvider accessTokenProvider;

  /// Language code sent so the backend resolves seller-authored text.
  final String Function()? languageProvider;
  final http.Client? client;

  Future<List<MarketProduct>> getProducts({
    MarketCategory? category,
    String? search,
  }) async {
    final data = await _request('/api/market/products', {
      if (category != null) 'category': category.name,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    });
    final products = data['products'];
    if (products is! List<dynamic>) {
      throw const MarketRemoteFailure(MarketRemoteFailureType.server);
    }
    try {
      return products
          .map(
            (value) =>
                MarketProductMapper.fromJson(value as Map<String, dynamic>),
          )
          .toList(growable: false);
    } catch (_) {
      throw const MarketRemoteFailure(MarketRemoteFailureType.server);
    }
  }

  Future<MarketProduct> getProduct(String id) async {
    final data = await _request('/api/market/products/$id', const {});
    try {
      return MarketProductMapper.fromJson(data);
    } catch (_) {
      throw const MarketRemoteFailure(MarketRemoteFailureType.server);
    }
  }

  Future<Map<String, dynamic>> _request(
    String path,
    Map<String, String> query, {
    bool retried = false,
  }) async {
    final token = await accessTokenProvider(forceRefresh: retried);
    if (token == null) {
      throw const MarketRemoteFailure(MarketRemoteFailureType.unauthorized);
    }
    final language = languageProvider?.call();
    final requestClient = client ?? http.Client();
    try {
      final uri = Uri.parse(baseUrl).resolve(path).replace(
        queryParameters: {
          ...query,
          if (language != null && language.isNotEmpty) 'language': language,
        },
      );
      final response = await requestClient
          .get(uri, headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          })
          .timeout(AppEnvironment.requestTimeout);
      if (response.statusCode == 401 && !retried) {
        return _request(path, query, retried: true);
      }
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint(
            'Market API $path failed with HTTP ${response.statusCode}: '
            '${_errorMessage(decoded) ?? 'Unknown error'}',
          );
        }
        throw MarketRemoteFailure(
          response.statusCode == 401
              ? MarketRemoteFailureType.unauthorized
              : response.statusCode == 404
              ? MarketRemoteFailureType.notFound
              : MarketRemoteFailureType.server,
          _errorMessage(decoded),
        );
      }
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw const MarketRemoteFailure(MarketRemoteFailureType.server);
      }
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw const MarketRemoteFailure(MarketRemoteFailureType.server);
      }
      return data;
    } on SocketException {
      throw const MarketRemoteFailure(MarketRemoteFailureType.offline);
    } on TimeoutException {
      throw const MarketRemoteFailure(MarketRemoteFailureType.offline);
    } on http.ClientException {
      throw const MarketRemoteFailure(MarketRemoteFailureType.offline);
    } on FormatException {
      throw const MarketRemoteFailure(MarketRemoteFailureType.server);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  String? _errorMessage(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final error = decoded['error'];
    return error is Map<String, dynamic> ? error['message'] as String? : null;
  }
}
