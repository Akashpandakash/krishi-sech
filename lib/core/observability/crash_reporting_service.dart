import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/core/observability/firebase_initializer.dart';

/// Routes uncaught Flutter, Dart and platform errors to Crashlytics.
///
/// Every entry point is failure tolerant: a missing or broken Firebase setup
/// must never stop the app from starting, so initialization degrades to a
/// no-op and the recording helpers fall back to the debug console.
abstract final class CrashReportingService {
  static bool _initialized = false;
  static FirebaseCrashlytics? _crashlytics;

  /// True once Firebase is up and the error handlers are installed.
  static bool get isReady => _crashlytics != null;

  /// Boots Crashlytics and installs the global error handlers. Safe to call
  /// more than once; only the first call does any work.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!await FirebaseInitializer.ensureInitialized()) return;

    final crashlytics = FirebaseCrashlytics.instance;
    try {
      await crashlytics.setCrashlyticsCollectionEnabled(
        AppEnvironment.crashReportingEnabled,
      );
    } catch (error, stackTrace) {
      _debugLog('Crash reporting unavailable: $error', stackTrace);
      return;
    }
    _crashlytics = crashlytics;

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      previousOnError?.call(details);
      unawaited(crashlytics.recordFlutterFatalError(details));
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      unawaited(crashlytics.recordError(error, stackTrace, fatal: true));
      return true;
    };

    unawaited(crashlytics.setCustomKey('app_env', AppEnvironment.appEnv));
  }

  /// Reports a handled error that the app recovered from.
  static Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    _debugLog(
      'Non-fatal error${reason == null ? '' : ' ($reason)'}: $error',
      stackTrace,
    );
    final crashlytics = _crashlytics;
    if (crashlytics == null) return;
    try {
      await crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
        printDetails: false,
      );
    } catch (_) {
      // Never let telemetry failures surface to the caller.
    }
  }

  /// Adds a breadcrumb to the next report. Useful right before an operation
  /// that is suspected of crashing.
  static Future<void> log(String message) async {
    final crashlytics = _crashlytics;
    if (crashlytics == null) return;
    try {
      await crashlytics.log(message);
    } catch (_) {
      // Ignore.
    }
  }

  /// Associates subsequent reports with the signed-in user, or clears the
  /// association when [userId] is null.
  static Future<void> setUserId(String? userId) async {
    final crashlytics = _crashlytics;
    if (crashlytics == null) return;
    try {
      await crashlytics.setUserIdentifier(userId ?? '');
    } catch (_) {
      // Ignore.
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
    _crashlytics = null;
  }
}
