import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show NavigatorObserver;
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/core/observability/firebase_initializer.dart';

/// Thin wrapper over Firebase Analytics.
///
/// Every method is a no-op until [initialize] succeeds, so callers can log
/// freely without guarding on whether Firebase came up. Nothing here ever
/// throws or awaits a network round trip on a UI path.
abstract final class AnalyticsService {
  static bool _initialized = false;
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;

  /// True once Firebase is up and analytics calls are being forwarded.
  static bool get isReady => _analytics != null;

  /// Navigator observer that logs a `screen_view` for every named route.
  /// Null until [initialize] succeeds; filter it out of `navigatorObservers`.
  static NavigatorObserver? get navigatorObserver => _observer;

  /// Boots analytics. Safe to call more than once; only the first call works.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!await FirebaseInitializer.ensureInitialized()) return;

    final analytics = FirebaseAnalytics.instance;
    try {
      await analytics.setAnalyticsCollectionEnabled(
        AppEnvironment.analyticsEnabled,
      );
    } catch (error, stackTrace) {
      _debugLog('Analytics unavailable: $error', stackTrace);
      return;
    }
    _analytics = analytics;
    _observer = FirebaseAnalyticsObserver(analytics: analytics);
    await setUserProperty('app_env', AppEnvironment.appEnv);
  }

  /// Logs a custom event. [name] must be snake_case, 1-40 characters, and
  /// parameter values must be `String` or `num` — Firebase rejects anything
  /// else, so non-conforming values are dropped rather than sent.
  static Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {
    final analytics = _analytics;
    if (analytics == null) return;
    final sanitized = <String, Object>{};
    parameters?.forEach((key, value) {
      if (value is String || value is num) sanitized[key] = value!;
    });
    await _guard(
      () => analytics.logEvent(
        name: name,
        parameters: sanitized.isEmpty ? null : sanitized,
      ),
    );
  }

  /// Logs a manual screen view. Named routes are already covered by
  /// [navigatorObserver]; use this for tabs and other in-page surfaces.
  static Future<void> logScreenView(String screenName) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await _guard(() => analytics.logScreenView(screenName: screenName));
  }

  static Future<void> logLogin(String method) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await _guard(() => analytics.logLogin(loginMethod: method));
  }

  static Future<void> logSignUp(String method) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await _guard(() => analytics.logSignUp(signUpMethod: method));
  }

  /// Associates subsequent events with the signed-in user, or clears the
  /// association when [userId] is null.
  static Future<void> setUserId(String? userId) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await _guard(() => analytics.setUserId(id: userId));
  }

  static Future<void> setUserProperty(String name, String? value) async {
    final analytics = _analytics;
    if (analytics == null) return;
    await _guard(() => analytics.setUserProperty(name: name, value: value));
  }

  static Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } catch (error, stackTrace) {
      _debugLog('Analytics call failed: $error', stackTrace);
    }
  }

  static void _debugLog(String message, StackTrace? stackTrace) {
    if (!kDebugMode || !AppEnvironment.loggingEnabled) return;
    debugPrint(message);
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
  }

  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    _analytics = null;
    _observer = null;
  }
}
