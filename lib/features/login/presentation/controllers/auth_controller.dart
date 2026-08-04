import 'package:flutter/foundation.dart';
import 'package:krishi_sech/features/login/domain/entities/auth_session.dart';
import 'package:krishi_sech/features/login/domain/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController(this.repository);

  final AuthRepository repository;
  AuthSession? _session;
  bool _isLoading = false;
  AuthFailure? _failure;

  AuthSession? get session => _session;
  bool get isAuthenticated => _session != null;
  bool get isLoading => _isLoading;
  AuthFailure? get failure => _failure;

  Future<void> initialize() async {
    await _run(() async => _session = await repository.restoreSession());
  }

  Future<OtpDispatch?> sendOtp(String phone) async {
    OtpDispatch? dispatch;
    await _run(() async => dispatch = await repository.sendOtp(phone));
    return dispatch;
  }

  Future<bool> verifyOtp(String phone, String otp) async {
    await _run(() async => _session = await repository.verifyOtp(phone, otp));
    return _session != null && _failure == null;
  }

  Future<bool> verifyDemoOtp(String otp) async {
    await _run(() async {
      if (otp != '123456') {
        throw const AuthFailure(AuthFailureType.validation, 'Invalid OTP');
      }
      _session = await repository.createDemoSession();
    });
    return _session != null && _failure == null;
  }

  Future<String?> getAccessToken({bool forceRefresh = false}) =>
      repository.getAccessToken(forceRefresh: forceRefresh);

  Future<void> logout() async {
    await _run(repository.logout);
    _session = null;
    notifyListeners();
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (_isLoading) return;
    _isLoading = true;
    _failure = null;
    notifyListeners();
    try {
      await operation();
    } on AuthFailure catch (failure) {
      _failure = failure;
    } catch (_) {
      _failure = const AuthFailure(AuthFailureType.server);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
