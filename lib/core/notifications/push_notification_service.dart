import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/core/notifications/device_registration_data_source.dart';
import 'package:krishi_sech/core/observability/firebase_initializer.dart';

/// Called when a push is opened, with the message's `data` payload so the
/// caller can route to the screen the notification refers to.
typedef PushOpenedCallback = void Function(Map<String, dynamic> data);

/// Handles messages delivered while the app is terminated or backgrounded.
///
/// Must be a top-level function: the platform spawns a separate isolate that
/// does not share any state with the running app, so Firebase has to be
/// initialized again here.
@pragma('vm:entry-point')
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  await FirebaseInitializer.ensureInitialized();
}

/// Registers the device for FCM and keeps the backend's token registry current.
///
/// Every step is best effort: push is an enhancement, so a farmer who denies
/// the permission, runs without Play Services, or is offline must still get a
/// working app.
class PushNotificationService {
  PushNotificationService({required this.deviceRegistrations});

  final DeviceRegistrationDataSource deviceRegistrations;

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  PushOpenedCallback? _onOpened;
  String? _registeredToken;
  bool _started = false;

  /// Set up messaging and register the current token with the backend.
  Future<void> initialize({PushOpenedCallback? onOpened}) async {
    if (_started) return;
    _onOpened = onOpened;
    if (!await FirebaseInitializer.ensureInitialized()) return;
    _started = true;

    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission();
      // Without this, iOS shows nothing while the app is in the foreground.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened),
      );
      // A push that launched the app from terminated is delivered here once.
      final initial = await messaging.getInitialMessage();
      if (initial != null) _handleOpened(initial);

      // Rotation must reach the backend or delivery silently stops.
      _subscriptions.add(
        messaging.onTokenRefresh.listen((token) {
          unawaited(_register(token));
        }),
      );

      final token = await messaging.getToken();
      if (token != null) await _register(token);
    } catch (error, stackTrace) {
      _log('Push initialization failed: $error', stackTrace);
    }
  }

  /// Re-sends the token after a sign-in so it is attached to the new account.
  Future<void> syncRegistration() async {
    if (!_started) return;
    try {
      final token = _registeredToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token, force: true);
    } catch (error, stackTrace) {
      _log('Push token sync failed: $error', stackTrace);
    }
  }

  /// Detaches this device on sign-out so it stops receiving that account's
  /// notifications while another farmer uses the handset.
  Future<void> unregister() async {
    final token = _registeredToken;
    _registeredToken = null;
    if (token == null) return;
    try {
      await deviceRegistrations.unregister(token);
    } catch (error, stackTrace) {
      _log('Push unregister failed: $error', stackTrace);
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _started = false;
  }

  Future<void> _register(String token, {bool force = false}) async {
    if (!force && token == _registeredToken) return;
    try {
      await deviceRegistrations.register(token);
      _registeredToken = token;
    } catch (error, stackTrace) {
      // Leave _registeredToken unset so the next sync retries.
      _log('Device registration failed: $error', stackTrace);
    }
  }

  void _handleOpened(RemoteMessage message) {
    final callback = _onOpened;
    if (callback != null) callback(message.data);
  }

  void _log(String message, [StackTrace? stackTrace]) {
    if (kDebugMode && AppEnvironment.loggingEnabled) {
      debugPrint('[Push] $message');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }
  }
}
