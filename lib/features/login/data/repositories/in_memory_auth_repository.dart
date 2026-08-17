import 'package:krishi_sech/features/login/domain/entities/auth_session.dart';
import 'package:krishi_sech/features/login/domain/repositories/auth_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  AuthSession? _session;

  @override
  Future<OtpDispatch> sendOtp(String phone) async =>
      const OtpDispatch(debugOtp: '123456');

  @override
  Future<AuthSession> verifyOtp(String phone, String otp) async {
    if (otp != '123456') {
      throw const AuthFailure(AuthFailureType.validation, 'Invalid OTP');
    }
    _session = AuthSession(
      user: AuthUser(
        id: 'local-user',
        phone: phone,
        preferredLanguage: 'en',
        isActive: true,
      ),
      accessToken: 'local-access-token',
      refreshToken: 'local-refresh-token',
    );
    return _session!;
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    _session = const AuthSession(
      user: AuthUser(
        id: 'local-google-user',
        phone: null,
        preferredLanguage: 'en',
        isActive: true,
      ),
      accessToken: 'local-access-token',
      refreshToken: 'local-refresh-token',
    );
    return _session!;
  }

  @override
  Future<AuthSession> createDemoSession() async {
    _session = const AuthSession(
      user: AuthUser(
        id: 'demo-farmer',
        phone: '+919999999999',
        name: 'Demo Farmer',
        preferredLanguage: 'en',
        isActive: true,
      ),
      accessToken: 'local-demo-access-token',
      refreshToken: 'local-demo-refresh-token',
    );
    return _session!;
  }

  @override
  Future<AuthSession?> restoreSession() async => _session;

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async =>
      _session?.accessToken;

  @override
  Future<void> logout() async => _session = null;
}
