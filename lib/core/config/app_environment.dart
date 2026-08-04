import 'package:flutter/foundation.dart';

abstract final class AppEnvironment {
  static const appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
  static const requestTimeoutMs = int.fromEnvironment(
    'REQUEST_TIMEOUT_MS',
    defaultValue: 25000,
  );
  static const _loggingRequested = bool.fromEnvironment(
    'LOGGING_ENABLED',
    defaultValue: true,
  );
  static const _demoLoginRequested = bool.fromEnvironment(
    'DEMO_LOGIN_ENABLED',
    defaultValue: true,
  );
  static const debugOtpEnabled = bool.fromEnvironment(
    'DEBUG_OTP_ENABLED',
    defaultValue: true,
  );
  static const openAiEnabled = bool.fromEnvironment(
    'OPENAI_ENABLED',
    defaultValue: true,
  );

  static const isDevelopment = appEnv == 'development';
  static const isStaging = appEnv == 'staging';
  static const isProduction = appEnv == 'production';
  static const loggingEnabled = !isProduction && _loggingRequested;

  static const demoModeEnabled =
      !isProduction &&
      _demoLoginRequested &&
      (isStaging || (!kProfileMode && !kReleaseMode));

  static Duration get requestTimeout =>
      Duration(milliseconds: requestTimeoutMs > 0 ? requestTimeoutMs : 25000);

  static void validate() => validateValues(
    environment: appEnv,
    apiUrl: apiBaseUrl,
    requestTimeoutMs: requestTimeoutMs,
    demoLoginEnabled: _demoLoginRequested,
    debugOtpEnabled: debugOtpEnabled,
  );

  @visibleForTesting
  static void validateValues({
    required String environment,
    required String apiUrl,
    required int requestTimeoutMs,
    required bool demoLoginEnabled,
    required bool debugOtpEnabled,
  }) {
    if (!const {'development', 'staging', 'production'}.contains(environment)) {
      throw StateError('APP_ENV must be development, staging, or production');
    }
    if (requestTimeoutMs <= 0) {
      throw StateError('REQUEST_TIMEOUT_MS must be greater than zero');
    }
    final uri = Uri.tryParse(apiUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_BASE_URL must be an absolute URL');
    }
    if (environment == 'development') return;
    if (uri.scheme != 'https') {
      throw StateError('$environment API_BASE_URL must use HTTPS');
    }
    if (environment == 'production') {
      final host = uri.host.toLowerCase();
      if (_isLocalOrPrivateHost(host)) {
        throw StateError('Production API_BASE_URL cannot use a local host');
      }
      if (demoLoginEnabled) {
        throw StateError('Demo login must be disabled in production');
      }
      if (debugOtpEnabled) {
        throw StateError('Debug OTP must be disabled in production');
      }
    }
  }

  static bool _isLocalOrPrivateHost(String host) {
    if (host == 'localhost' || host == '10.0.2.2' || host == '::1') return true;
    final parts = host.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) return false;
    final first = parts[0]!;
    final second = parts[1]!;
    return first == 10 ||
        first == 127 ||
        first == 0 ||
        (first == 169 && second == 254) ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168);
  }

  static bool demoModeFor({
    required bool debug,
    required bool profile,
    required bool release,
    required String environment,
  }) => !profile && !release && (debug || environment == 'development');
}
