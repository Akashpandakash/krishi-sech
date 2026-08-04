import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/features/login/data/models/auth_session_model.dart';
import 'package:krishi_sech/features/login/domain/entities/auth_session.dart';
import 'package:krishi_sech/features/login/domain/repositories/auth_repository.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource({required this.baseUrl, this.client});

  final String baseUrl;
  final http.Client? client;

  Future<OtpDispatch> sendOtp(String phone) async {
    final data = await _request(
      '/api/auth/send-otp',
      body: {'phone': phone},
      logDevelopmentResponse: true,
    );
    return OtpDispatch(
      debugOtp: AppEnvironment.debugOtpEnabled
          ? (data?['debugOtp'] as String?)
          : null,
    );
  }

  Future<AuthSession> verifyOtp(String phone, String otp) async {
    final data = await _request(
      '/api/auth/verify-otp',
      body: {'phone': phone, 'otp': otp},
    );
    return AuthSessionModel.fromJson(data!).toEntity();
  }

  Future<AuthUser> me(String accessToken) async {
    final data = await _request(
      '/api/auth/me',
      method: 'GET',
      accessToken: accessToken,
    );
    return AuthSessionModel.fromJson({
      'user': data,
      'accessToken': accessToken,
      'refreshToken': 'unused',
    }).user;
  }

  Future<AuthSession> refresh(String refreshToken) async {
    final data = await _request(
      '/api/auth/refresh',
      body: {'refreshToken': refreshToken},
    );
    return AuthSessionModel.fromJson(data!).toEntity();
  }

  Future<void> logout(String refreshToken) =>
      _request('/api/auth/logout', body: {'refreshToken': refreshToken});

  Future<Map<String, dynamic>?> _request(
    String path, {
    String method = 'POST',
    Map<String, String>? body,
    String? accessToken,
    bool logDevelopmentResponse = false,
  }) async {
    final requestClient = client ?? http.Client();
    final stopwatch = Stopwatch()..start();
    try {
      final uri = Uri.parse(baseUrl).resolve(path);
      final headers = <String, String>{
        'Accept': 'application/json',
        if (AppEnvironment.demoModeEnabled)
          'X-Krishi-Development-Client': 'true',
        if (body != null) 'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };
      final response = method == 'GET'
          ? await requestClient
                .get(uri, headers: headers)
                .timeout(AppEnvironment.requestTimeout)
          : await requestClient
                .post(uri, headers: headers, body: jsonEncode(body))
                .timeout(AppEnvironment.requestTimeout);
      if (kDebugMode &&
          AppEnvironment.loggingEnabled &&
          logDevelopmentResponse) {
        debugPrint(
          'Auth HTTP url=$uri status=${response.statusCode} '
          'responseTimeMs=${stopwatch.elapsedMilliseconds}',
        );
      }
      final decoded = jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final type = response.statusCode == 401
            ? AuthFailureType.unauthorized
            : response.statusCode == 400 || response.statusCode == 429
            ? AuthFailureType.validation
            : AuthFailureType.server;
        throw AuthFailure(type, _message(decoded));
      }
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw const AuthFailure(AuthFailureType.server);
      }
      final data = decoded['data'];
      if (data == null) return null;
      if (data is! Map<String, dynamic>) {
        throw const AuthFailure(AuthFailureType.server);
      }
      return data;
    } on SocketException {
      throw const AuthFailure(AuthFailureType.offline);
    } on TimeoutException {
      throw const AuthFailure(AuthFailureType.timeout);
    } on http.ClientException {
      throw const AuthFailure(AuthFailureType.offline);
    } on FormatException {
      throw const AuthFailure(AuthFailureType.server);
    } finally {
      if (client == null) requestClient.close();
    }
  }

  String? _message(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;
    final error = decoded['error'];
    return error is Map<String, dynamic> ? error['message'] as String? : null;
  }
}
