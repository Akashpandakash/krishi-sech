export type AppEnvironmentName = 'development' | 'staging' | 'production';

export interface AppConfig {
  appEnv: AppEnvironmentName;
  requestTimeoutMs: number;
  loggingEnabled: boolean;
  demoLoginEnabled: boolean;
  debugOtpEnabled: boolean;
  openAiEnabled: boolean;
  weatherProvider: 'open-meteo';
  weatherApiBaseUrl: string;
  trustProxy: boolean;
  corsAllowedOrigins: string[];
  rateLimitWindowMs: number;
  authRateLimitMax: number;
  aiRateLimitMax: number;
}

type EnvironmentValues = Record<string, string | undefined>;

function booleanValue(
  values: EnvironmentValues,
  name: string,
  fallback: boolean,
): boolean {
  const raw = values[name]?.trim().toLowerCase();
  if (!raw) return fallback;
  if (raw === 'true') return true;
  if (raw === 'false') return false;
  throw new Error(`${name} must be true or false`);
}

function positiveInteger(
  values: EnvironmentValues,
  name: string,
  fallback: number,
): number {
  const parsed = Number.parseInt(values[name] ?? '', 10);
  if (!values[name]) return fallback;
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error(`${name} must be a positive integer`);
  }
  return parsed;
}

export function loadAppConfig(
  values: EnvironmentValues = process.env,
): AppConfig {
  const rawEnvironment = values.APP_ENV?.trim() || 'development';
  if (!['development', 'staging', 'production'].includes(rawEnvironment)) {
    throw new Error('APP_ENV must be development, staging, or production');
  }
  const appEnv = rawEnvironment as AppEnvironmentName;
  const production = appEnv === 'production';
  const staging = appEnv === 'staging';
  const loggingEnabled = booleanValue(
    values,
    'LOGGING_ENABLED',
    appEnv === 'development',
  );
  const demoLoginEnabled = booleanValue(
    values,
    'DEMO_LOGIN_ENABLED',
    appEnv === 'development',
  );
  const debugOtpEnabled = booleanValue(
    values,
    'DEBUG_OTP_ENABLED',
    appEnv === 'development',
  );
  const openAiEnabled = booleanValue(values, 'OPENAI_ENABLED', true);
  const trustProxy = booleanValue(values, 'TRUST_PROXY', false);
  const corsAllowedOrigins = (values.CORS_ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  if (production && corsAllowedOrigins.includes('*')) {
    throw new Error('Production CORS cannot use a wildcard origin');
  }
  for (const origin of corsAllowedOrigins) {
    if (origin === '*' && !production) continue;
    const parsed = new URL(origin);
    if (!['http:', 'https:'].includes(parsed.protocol) || parsed.origin !== origin) {
      throw new Error('CORS_ALLOWED_ORIGINS must contain URL origins only');
    }
  }
  const weatherProvider = values.WEATHER_PROVIDER?.trim() || 'open-meteo';
  if (weatherProvider !== 'open-meteo') {
    throw new Error('WEATHER_PROVIDER must be open-meteo');
  }
  const weatherApiBaseUrl =
    values.WEATHER_API_BASE_URL?.trim() ||
    'https://api.open-meteo.com/v1/forecast';
  const weatherUri = new URL(weatherApiBaseUrl);
  if ((staging || production) && weatherUri.protocol !== 'https:') {
    throw new Error('Weather provider must use HTTPS outside development');
  }
  if (production && loggingEnabled) {
    throw new Error('LOGGING_ENABLED must be false in production');
  }
  if (production && demoLoginEnabled) {
    throw new Error('DEMO_LOGIN_ENABLED must be false in production');
  }
  if (production && debugOtpEnabled) {
    throw new Error('DEBUG_OTP_ENABLED must be false in production');
  }
  if (production && openAiEnabled && !values.OPENAI_API_KEY?.trim()) {
    throw new Error('OPENAI_API_KEY is required when OpenAI is enabled');
  }
  return {
    appEnv,
    requestTimeoutMs: positiveInteger(
      values,
      'REQUEST_TIMEOUT_MS',
      20_000,
    ),
    loggingEnabled,
    demoLoginEnabled,
    debugOtpEnabled,
    openAiEnabled,
    weatherProvider,
    weatherApiBaseUrl: weatherUri.toString(),
    trustProxy,
    corsAllowedOrigins,
    rateLimitWindowMs: positiveInteger(
      values,
      'RATE_LIMIT_WINDOW_MS',
      60_000,
    ),
    authRateLimitMax: positiveInteger(values, 'AUTH_RATE_LIMIT_MAX', 60),
    aiRateLimitMax: positiveInteger(values, 'AI_RATE_LIMIT_MAX', 30),
  };
}
