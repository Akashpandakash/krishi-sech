import 'package:krishi_sech/features/login/domain/entities/auth_session.dart';

class OtpDispatch {
  const OtpDispatch({this.debugOtp});
  final String? debugOtp;
}

enum AuthFailureType { offline, timeout, validation, unauthorized, server }

class AuthFailure implements Exception {
  const AuthFailure(this.type, [this.message]);
  final AuthFailureType type;
  final String? message;
}

abstract interface class AuthRepository {
  Future<OtpDispatch> sendOtp(String phone);
  Future<AuthSession> verifyOtp(String phone, String otp);
  Future<AuthSession> createDemoSession();
  Future<AuthSession?> restoreSession();
  Future<String?> getAccessToken({bool forceRefresh = false});
  Future<void> logout();
}
