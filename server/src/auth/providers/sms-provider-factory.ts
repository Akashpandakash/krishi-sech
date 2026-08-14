import type { AppConfig } from '../../config/app-config.js';
import { loadFast2SmsConfig } from '../../config/fast2sms-config.js';
import { DummySmsProvider } from './dummy-sms-provider.js';
import { Fast2SmsProvider } from './fast2sms-provider.js';
import type { SmsProvider } from './sms-provider.js';

type EnvironmentValues = Record<string, string | undefined>;

export function createSmsProvider(
  appConfig: AppConfig,
  values: EnvironmentValues = process.env,
): SmsProvider {
  if (appConfig.appEnv === 'development') return new DummySmsProvider();
  return new Fast2SmsProvider(
    loadFast2SmsConfig(values, appConfig.requestTimeoutMs),
    fetch,
    undefined,
    appConfig.appEnv === 'production',
  );
}
