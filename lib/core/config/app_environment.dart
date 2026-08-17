import 'package:flutter/foundation.dart';

abstract final class AppEnvironment {
  static const appEnv = 'development';
  static const apiBaseUrl = 'https://stage-api.krishisech.com';
  static const _loggingRequested = true;
  static const _demoLoginRequested = true;
  static const debugOtpEnabled = true;
  static const openAiEnabled = true;

  /// Telemetry is off in debug builds so local runs and hot reloads do not
  /// pollute the Firebase dashboards. Flip these to `true` to exercise
  /// Crashlytics or the Analytics DebugView from a debug build.
  static const crashReportingEnabled = !kDebugMode;
  static const analyticsEnabled = !kDebugMode;

  /// Web OAuth client ID. Android only issues an ID token with the audience
  /// the backend expects when this is supplied as serverClientId. Empty hides
  /// the Google sign-in button rather than offering a button that cannot work.
  static const googleServerClientId =
      '810187577371-apob0l8upe5g8qchccpucrvpr1prp2jo.apps.googleusercontent.com';

  static const isDevelopment = appEnv == 'development';
  static const isStaging = appEnv == 'staging';
  static const isProduction = appEnv == 'production';
  static const loggingEnabled = !isProduction && _loggingRequested;
  static const demoModeEnabled =
      isDevelopment && _demoLoginRequested && !kProfileMode && !kReleaseMode;

  static const requestTimeout = Duration(seconds: 25);

  static void validate() => validateValues(
    environment: appEnv,
    apiUrl: apiBaseUrl,
    demoLoginEnabled: _demoLoginRequested,
    debugOtpEnabled: debugOtpEnabled,
  );

  @visibleForTesting
  static void validateValues({
    required String environment,
    required String apiUrl,
    required bool demoLoginEnabled,
    required bool debugOtpEnabled,
  }) {
    if (!const {'development', 'staging', 'production'}.contains(environment)) {
      throw StateError('APP_ENV must be development, staging, or production');
    }
    final uri = Uri.tryParse(apiUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('API_BASE_URL must be an absolute URL');
    }
    if (environment == 'development') return;
    if (demoLoginEnabled) {
      throw StateError('Demo login must be disabled outside development');
    }
    if (debugOtpEnabled) {
      throw StateError('Debug OTP must be disabled outside development');
    }
    if (uri.scheme != 'https') {
      throw StateError('$environment API_BASE_URL must use HTTPS');
    }
    if (environment == 'production') {
      final host = uri.host.toLowerCase();
      if (_isLocalOrPrivateHost(host)) {
        throw StateError('Production API_BASE_URL cannot use a local host');
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
  }) => environment == 'development' && debug && !profile && !release;

  static bool locationDebugEnabledFor(String environment) =>
      environment == 'development';
}
