import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sech/core/config/app_environment.dart';

/// Supplies the current access token, or null when nobody is signed in.
typedef AccessTokenProvider = Future<String?> Function();

/// Sends this handset's FCM token to `/api/devices` so the backend can address
/// it. Registration is scoped to the signed-in account: the backend moves the
/// token to whichever user last registered it.
class DeviceRegistrationDataSource {
  DeviceRegistrationDataSource({
    required this.baseUrl,
    required this.accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final AccessTokenProvider accessToken;
  final http.Client _client;

  Future<void> register(String token) async {
    final platform = _platform();
    if (platform == null) return;
    await _send('POST', {'token': token, 'platform': platform});
  }

  Future<void> unregister(String token) =>
      _send('DELETE', {'token': token});

  Future<void> _send(String method, Map<String, Object?> body) async {
    final accessTokenValue = await accessToken();
    // Anonymous devices have no account to attach to; skip rather than fail.
    if (accessTokenValue == null || accessTokenValue.isEmpty) return;

    final request = http.Request(method, Uri.parse('$baseUrl/api/devices'))
      ..headers.addAll({
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $accessTokenValue',
      })
      ..body = jsonEncode(body);

    final streamed = await _client
        .send(request)
        .timeout(AppEnvironment.requestTimeout);
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode >= 400) {
      throw HttpException(
        'Device registration failed (${response.statusCode})',
        uri: request.url,
      );
    }
    if (kDebugMode && AppEnvironment.loggingEnabled) {
      debugPrint('[Push] device $method ok');
    }
  }

  static String? _platform() {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return null;
  }
}
