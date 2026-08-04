import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/app/router/app_router.dart';
import 'package:krishi_sech/app/router/app_routes.dart';
import 'package:krishi_sech/core/config/app_environment.dart';
import 'package:krishi_sech/features/login/domain/entities/auth_session.dart';
import 'package:krishi_sech/features/login/domain/repositories/auth_repository.dart';
import 'package:krishi_sech/features/login/presentation/auth_scope.dart';
import 'package:krishi_sech/features/login/presentation/controllers/auth_controller.dart';
import 'package:krishi_sech/features/login/presentation/pages/otp_page.dart';
import 'package:krishi_sech/l10n/generated/app_localizations.dart';

class _AuthRepositoryStub implements AuthRepository {
  _AuthRepositoryStub(this.sendOtpCallback, {this.createDemoSessionCallback});

  final Future<OtpDispatch> Function(String phone) sendOtpCallback;
  final Future<AuthSession> Function()? createDemoSessionCallback;
  int sendOtpCalls = 0;
  int verifyOtpCalls = 0;
  int createDemoSessionCalls = 0;

  @override
  Future<AuthSession> createDemoSession() {
    createDemoSessionCalls += 1;
    return createDemoSessionCallback?.call() ??
        Future<AuthSession>.error(UnimplementedError());
  }

  @override
  Future<OtpDispatch> sendOtp(String phone) {
    sendOtpCalls += 1;
    return sendOtpCallback(phone);
  }

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession> verifyOtp(String phone, String otp) {
    verifyOtpCalls += 1;
    return Future<AuthSession>.error(UnimplementedError());
  }
}

class _RouteObserver extends NavigatorObserver {
  int otpPushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == AppRoutes.otp) otpPushes += 1;
  }
}

Future<AuthController> _pumpLogin(
  WidgetTester tester,
  _AuthRepositoryStub repository, {
  NavigatorObserver? observer,
}) async {
  final controller = AuthController(repository);
  await tester.pumpWidget(
    AuthScope(
      controller: controller,
      child: MaterialApp(
        navigatorKey: AppRouter.navigatorKey,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: AppRoutes.login,
        onGenerateRoute: (settings) {
          if (settings.name == AppRoutes.home) {
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('test-home')),
            );
          }
          return AppRouter.onGenerateRoute(settings);
        },
        navigatorObservers: [?observer],
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), '9123456789');
  return controller;
}

void main() {
  testWidgets('debug demo phone opens OTP screen with prefilled demo OTP', (
    tester,
  ) async {
    final repository = _AuthRepositoryStub(
      (_) => Completer<OtpDispatch>().future,
      createDemoSessionCallback: () async {
        return const AuthSession(
          user: AuthUser(
            id: 'demo-user',
            phone: '+919999999999',
            name: 'Demo Farmer',
            preferredLanguage: 'en',
            isActive: true,
          ),
          accessToken: 'normal-jwt',
          refreshToken: 'normal-refresh-token',
        );
      },
    );
    final controller = await _pumpLogin(tester, repository);
    await tester.enterText(find.byType(TextField), '9999999999');

    expect(find.byKey(const Key('demo_mode_label')), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(repository.sendOtpCalls, 0);
    expect(controller.isLoading, isFalse);
    final otpPage = tester.widget<OtpPage>(find.byType(OtpPage));
    expect(otpPage.arguments.phone, '+919999999999');
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('otp_field')))
          .controller
          ?.text,
      '123456',
    );
    expect(find.byKey(const Key('otp_demo_mode_label')), findsOneWidget);

    await tester.tap(find.byKey(const Key('verify_otp_button')));
    await tester.pumpAndSettle();
    expect(repository.verifyOtpCalls, 0);
    expect(repository.createDemoSessionCalls, 1);
    expect(controller.isLoading, isFalse);
    expect(controller.session?.accessToken, 'normal-jwt');
    expect(find.text('test-home'), findsOneWidget);
  });

  test('demo mode is disabled for profile and release builds', () {
    expect(
      AppEnvironment.demoModeFor(
        debug: false,
        profile: false,
        release: true,
        environment: 'development',
      ),
      isFalse,
    );
    expect(
      AppEnvironment.demoModeFor(
        debug: false,
        profile: true,
        release: false,
        environment: 'development',
      ),
      isFalse,
    );
  });

  testWidgets('HTTP 200 dispatch opens OTP screen with phone and debug OTP', (
    tester,
  ) async {
    final repository = _AuthRepositoryStub(
      (_) async => const OtpDispatch(debugOtp: '123456'),
    );
    final observer = _RouteObserver();
    await _pumpLogin(tester, repository, observer: observer);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    final otpPage = tester.widget<OtpPage>(find.byType(OtpPage));
    expect(otpPage.arguments.phone, '+919123456789');
    expect(otpPage.arguments.debugOtp, '123456');
    final otpField = tester.widget<TextField>(
      find.byKey(const Key('otp_field')),
    );
    expect(otpField.controller?.text, '123456');
    expect(observer.otpPushes, 1);
  });

  testWidgets('invalid success response shows localized retry error', (
    tester,
  ) async {
    final repository = _AuthRepositoryStub(
      (_) => Future.error(const AuthFailure(AuthFailureType.server)),
    );
    await _pumpLogin(tester, repository);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(
      find.text('Authentication could not be completed. Please retry.'),
      findsOneWidget,
    );
    expect(find.byType(OtpPage), findsNothing);
  });

  testWidgets('network error clears loading and leaves retry enabled', (
    tester,
  ) async {
    final repository = _AuthRepositoryStub(
      (_) => Future.error(const AuthFailure(AuthFailureType.offline)),
    );
    final controller = await _pumpLogin(tester, repository);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(controller.isLoading, isFalse);
    expect(
      find.text('You are offline. Check your connection and retry.'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Continue'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('repeated taps create only one request and one OTP navigation', (
    tester,
  ) async {
    final pending = Completer<OtpDispatch>();
    final repository = _AuthRepositoryStub((_) => pending.future);
    final observer = _RouteObserver();
    await _pumpLogin(tester, repository, observer: observer);

    final continueButton = find.widgetWithText(FilledButton, 'Continue');
    await tester.tap(continueButton);
    await tester.tap(continueButton);
    await tester.pump();
    expect(repository.sendOtpCalls, 1);

    pending.complete(const OtpDispatch());
    await tester.pumpAndSettle();
    expect(observer.otpPushes, 1);
  });
}
