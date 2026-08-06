abstract final class HelpSupportConfig {
  static const supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@example.com',
  );
  static const supportPhone = String.fromEnvironment(
    'SUPPORT_PHONE',
    defaultValue: '+91 00000 00000',
  );
  static const appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0+1',
  );
}
