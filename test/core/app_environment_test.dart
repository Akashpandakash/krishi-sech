import 'package:flutter_test/flutter_test.dart';
import 'package:krishi_sech/core/config/app_environment.dart';

void main() {
  group('production Flutter environment validation', () {
    void validate({
      String apiUrl = 'https://api.krishisech.example',
      bool demoLoginEnabled = false,
      bool debugOtpEnabled = false,
    }) => AppEnvironment.validateValues(
      environment: 'production',
      apiUrl: apiUrl,
      requestTimeoutMs: 25000,
      demoLoginEnabled: demoLoginEnabled,
      debugOtpEnabled: debugOtpEnabled,
    );

    test('accepts a public HTTPS API URL with production flags disabled', () {
      expect(validate, returnsNormally);
    });

    test('rejects HTTP, localhost, emulator, and private LAN URLs', () {
      for (final url in [
        'http://api.krishisech.example',
        'https://localhost:3000',
        'https://10.0.2.2:3000',
        'https://192.168.1.10:3000',
        'https://10.20.30.40:3000',
        'https://172.16.5.4:3000',
      ]) {
        expect(() => validate(apiUrl: url), throwsStateError, reason: url);
      }
    });

    test('rejects production demo login and debug OTP', () {
      expect(() => validate(demoLoginEnabled: true), throwsStateError);
      expect(() => validate(debugOtpEnabled: true), throwsStateError);
    });

    test('allows local HTTP only in development', () {
      expect(
        () => AppEnvironment.validateValues(
          environment: 'development',
          apiUrl: 'http://192.168.1.10:3000',
          requestTimeoutMs: 25000,
          demoLoginEnabled: true,
          debugOtpEnabled: true,
        ),
        returnsNormally,
      );
    });
  });
}
