import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/features/login/domain/entities/auth_session.dart';
import 'package:krishi_sech/features/login/domain/repositories/auth_repository.dart';
import 'package:krishi_sech/features/login/presentation/controllers/auth_controller.dart';

class _AuthRepositoryStub implements AuthRepository {
  _AuthRepositoryStub(this.sendOtpResult);

  final Future<OtpDispatch> Function() sendOtpResult;

  @override
  Future<OtpDispatch> sendOtp(String phone) => sendOtpResult();

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession?> restoreSession() async => null;

  @override
  Future<AuthSession> verifyOtp(String phone, String otp) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> createDemoSession() => throw UnimplementedError();
}

void main() {
  test('sendOtp clears loading after success', () async {
    final pending = Completer<OtpDispatch>();
    final controller = AuthController(
      _AuthRepositoryStub(() => pending.future),
    );

    final request = controller.sendOtp('+919123456789');
    expect(controller.isLoading, isTrue);

    pending.complete(const OtpDispatch(debugOtp: '123456'));
    expect(await request, isNotNull);
    expect(controller.isLoading, isFalse);
    expect(controller.failure, isNull);
  });

  test('sendOtp clears loading and records failure after error', () async {
    final pending = Completer<OtpDispatch>();
    final controller = AuthController(
      _AuthRepositoryStub(() => pending.future),
    );

    final request = controller.sendOtp('+919123456789');
    expect(controller.isLoading, isTrue);

    pending.completeError(const AuthFailure(AuthFailureType.server));
    expect(await request, isNull);
    expect(controller.isLoading, isFalse);
    expect(controller.failure?.type, AuthFailureType.server);
  });
}
