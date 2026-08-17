import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/core/observability/analytics_service.dart';
import 'package:krishi_sech/core/observability/crash_reporting_service.dart';
import 'package:krishi_sech/core/observability/firebase_initializer.dart';

/// Firebase has no platform channels under `flutter test`, so this suite runs
/// in exactly the state the app must survive in the field: Firebase missing.
/// Telemetry is a side channel and must never break the caller.
void main() {
  setUp(() {
    FirebaseInitializer.resetForTesting();
    CrashReportingService.resetForTesting();
    AnalyticsService.resetForTesting();
  });

  tearDown(() {
    FirebaseInitializer.resetForTesting();
    CrashReportingService.resetForTesting();
    AnalyticsService.resetForTesting();
  });

  group('telemetry defaults', () {
    test('are disabled in debug builds so dashboards stay clean', () {
      expect(AppEnvironment.crashReportingEnabled, isFalse);
      expect(AppEnvironment.analyticsEnabled, isFalse);
    });
  });

  group('crash reporting without Firebase', () {
    test('initializes without throwing and stays unready', () async {
      await expectLater(CrashReportingService.initialize(), completes);
      expect(CrashReportingService.isReady, isFalse);
    });

    test('does not replace the global error handlers', () async {
      final original = FlutterError.onError;
      await CrashReportingService.initialize();
      expect(FlutterError.onError, same(original));
    });

    test('recording is a safe no-op', () async {
      await CrashReportingService.initialize();
      await expectLater(
        CrashReportingService.recordError(
          StateError('boom'),
          StackTrace.current,
          reason: 'unit test',
        ),
        completes,
      );
      await expectLater(CrashReportingService.log('breadcrumb'), completes);
      await expectLater(CrashReportingService.setUserId('user-1'), completes);
      await expectLater(CrashReportingService.setUserId(null), completes);
    });

    test('repeated initialization is idempotent', () async {
      await CrashReportingService.initialize();
      await expectLater(CrashReportingService.initialize(), completes);
    });
  });

  group('analytics without Firebase', () {
    test('initializes without throwing and exposes no observer', () async {
      await expectLater(AnalyticsService.initialize(), completes);
      expect(AnalyticsService.isReady, isFalse);
      expect(AnalyticsService.navigatorObserver, isNull);
    });

    test('logging is a safe no-op', () async {
      await AnalyticsService.initialize();
      await expectLater(
        AnalyticsService.logEvent('crop_added', parameters: {'crop': 'rice'}),
        completes,
      );
      await expectLater(AnalyticsService.logScreenView('home'), completes);
      await expectLater(AnalyticsService.logLogin('otp'), completes);
      await expectLater(AnalyticsService.logSignUp('otp'), completes);
      await expectLater(AnalyticsService.setUserId('user-1'), completes);
      await expectLater(
        AnalyticsService.setUserProperty('app_env', 'development'),
        completes,
      );
    });

    test('repeated initialization is idempotent', () async {
      await AnalyticsService.initialize();
      await expectLater(AnalyticsService.initialize(), completes);
    });
  });
}
