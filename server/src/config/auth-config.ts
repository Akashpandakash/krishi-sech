import { loadAppConfig } from './app-config.js';

export interface AuthConfig {
  accessTokenSecret: string;
  refreshTokenSecret: string;
  otpHashSecret: string;
  accessTokenTtlSeconds: number;
  refreshTokenTtlSeconds: number;
  otpTtlSeconds: number;
  otpRequestWindowSeconds: number;
  otpMaxRequestsPerWindow: number;
  exposeDebugOtp: boolean;
  demoLoginEnabled: boolean;
}

export function loadAuthConfig(): AuthConfig {
  const appConfig = loadAppConfig();
  const production = appConfig.appEnv === 'production';
  const integer = (name: string, fallback: number): number => {
    const parsed = Number.parseInt(process.env[name] ?? '', 10);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
  };
  const value = (name: string, developmentFallback: string): string => {
    const configured = process.env[name]?.trim();
    if (configured) return configured;
    if (production) throw new Error(`${name} must be configured in production`);
    return developmentFallback;
  };

  return {
    accessTokenSecret: value('JWT_ACCESS_SECRET', 'dev-access-secret-change-me'),
    refreshTokenSecret: value('JWT_REFRESH_SECRET', 'dev-refresh-secret-change-me'),
    otpHashSecret: value('OTP_HASH_SECRET', 'dev-otp-secret-change-me'),
    accessTokenTtlSeconds: 15 * 60,
    refreshTokenTtlSeconds: 30 * 24 * 60 * 60,
    otpTtlSeconds: 5 * 60,
    otpRequestWindowSeconds: integer('OTP_REQUEST_WINDOW_SECONDS', 10 * 60),
    otpMaxRequestsPerWindow: integer('OTP_MAX_REQUESTS_PER_WINDOW', 3),
    exposeDebugOtp:
      appConfig.debugOtpEnabled && process.env.NODE_ENV !== 'test',
    demoLoginEnabled: appConfig.demoLoginEnabled,
  };
}
