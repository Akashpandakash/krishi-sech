import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/firebase_options.dart';

/// Boots the default Firebase app exactly once for every Firebase-backed
/// service in the app (Crashlytics, Analytics, Messaging).
///
/// Initialization is best effort: a missing or broken Firebase configuration
/// must never stop the app from starting, so failures resolve to `false` and
/// the dependent services degrade to no-ops.
abstract final class FirebaseInitializer {
  static const _timeout = Duration(seconds: 8);

  static Future<bool>? _pending;

  /// Firebase only has a generated configuration for the mobile targets.
  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Initializes Firebase on first call and returns the same result to every
  /// later caller. Returns whether Firebase is usable.
  static Future<bool> ensureInitialized() => _pending ??= _initialize();

  static Future<bool> _initialize() async {
    if (!isSupportedPlatform) return false;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(_timeout);
      return true;
    } catch (error, stackTrace) {
      if (kDebugMode && AppEnvironment.loggingEnabled) {
        debugPrint('Firebase initialization failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return false;
    }
  }

  @visibleForTesting
  static void resetForTesting() => _pending = null;
}
