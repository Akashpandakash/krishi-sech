import { loadAppConfig } from './app-config.js';

export interface AdminConfig {
  accessTokenSecret: string;
  refreshTokenSecret: string;
  accessTokenTtlSeconds: number;
  refreshTokenTtlSeconds: number;
  maxFailedLogins: number;
  lockoutSeconds: number;
}

export function loadAdminConfig(
  values: NodeJS.ProcessEnv = process.env,
): AdminConfig {
  const production = loadAppConfig(values).appEnv === 'production';
  const secret = (name: string, developmentFallback: string): string => {
    const configured = values[name]?.trim();
    if (configured) return configured;
    if (production) throw new Error(`${name} must be configured in production`);
    return developmentFallback;
  };
  const integer = (name: string, fallback: number): number => {
    const parsed = Number.parseInt(values[name] ?? '', 10);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
  };

  return {
    accessTokenSecret: secret(
      'ADMIN_JWT_ACCESS_SECRET',
      'dev-admin-access-secret-change-me',
    ),
    refreshTokenSecret: secret(
      'ADMIN_JWT_REFRESH_SECRET',
      'dev-admin-refresh-secret-change-me',
    ),
    // Admin sessions are shorter than the app's: a panel session lives on a
    // shared desktop far more often than a phone does.
    accessTokenTtlSeconds: integer('ADMIN_ACCESS_TOKEN_TTL_SECONDS', 30 * 60),
    refreshTokenTtlSeconds: integer(
      'ADMIN_REFRESH_TOKEN_TTL_SECONDS',
      12 * 60 * 60,
    ),
    maxFailedLogins: integer('ADMIN_MAX_FAILED_LOGINS', 5),
    lockoutSeconds: integer('ADMIN_LOCKOUT_SECONDS', 15 * 60),
  };
}
