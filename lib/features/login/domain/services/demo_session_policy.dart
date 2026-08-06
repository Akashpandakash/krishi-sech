import '../entities/auth_session.dart';

class DemoSessionPolicy {
  const DemoSessionPolicy._();

  static const phone = '+919999999999';
  static const storageNamespace = 'demo';

  static bool matches(AuthUser? user, {required bool demoModeEnabled}) =>
      demoModeEnabled && user?.phone == phone;
}
