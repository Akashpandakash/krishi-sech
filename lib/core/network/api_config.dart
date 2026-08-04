import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:krishi_sech/core/config/app_environment.dart';

abstract final class ApiConfig {
  static String get baseUrl => AppEnvironment.apiBaseUrl;

  static Future<void> checkDevelopmentConnectivity() async {
    if (!kDebugMode || !AppEnvironment.loggingEnabled) return;
    final uri = Uri.parse(baseUrl).resolve('/api/health');
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      debugPrint(
        'API connectivity url=$uri status=${response.statusCode} '
        'responseTimeMs=${stopwatch.elapsedMilliseconds}',
      );
    } on TimeoutException {
      debugPrint(
        'API connectivity url=$uri status=timeout '
        'responseTimeMs=${stopwatch.elapsedMilliseconds} '
        'error=Backend did not respond in time',
      );
    } catch (_) {
      debugPrint(
        'API connectivity url=$uri status=unreachable '
        'responseTimeMs=${stopwatch.elapsedMilliseconds} '
        'error=Backend could not be reached',
      );
    }
  }
}
