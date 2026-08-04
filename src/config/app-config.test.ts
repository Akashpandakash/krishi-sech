import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { loadAppConfig } from './app-config.js';

const productionValues = {
  APP_ENV: 'production',
  REQUEST_TIMEOUT_MS: '20000',
  LOGGING_ENABLED: 'false',
  DEMO_LOGIN_ENABLED: 'false',
  DEBUG_OTP_ENABLED: 'false',
  OPENAI_ENABLED: 'true',
  OPENAI_API_KEY: 'test-placeholder',
  WEATHER_PROVIDER: 'open-meteo',
  WEATHER_API_BASE_URL: 'https://api.open-meteo.com/v1/forecast',
  TRUST_PROXY: 'true',
  CORS_ALLOWED_ORIGINS: 'https://admin.krishisech.com',
};

describe('application environment configuration', () => {
  it('accepts a production-safe configuration', () => {
    const config = loadAppConfig(productionValues);
    assert.equal(config.appEnv, 'production');
    assert.equal(config.loggingEnabled, false);
    assert.equal(config.demoLoginEnabled, false);
    assert.equal(config.debugOtpEnabled, false);
  });

  it('rejects production demo login, debug OTP, and logging', () => {
    for (const flag of [
      'DEMO_LOGIN_ENABLED',
      'DEBUG_OTP_ENABLED',
      'LOGGING_ENABLED',
    ]) {
      assert.throws(() => loadAppConfig({ ...productionValues, [flag]: 'true' }));
    }
  });

  it('requires HTTPS weather configuration outside development', () => {
    assert.throws(() =>
      loadAppConfig({
        ...productionValues,
        APP_ENV: 'staging',
        OPENAI_API_KEY: undefined,
        WEATHER_API_BASE_URL: 'http://weather.internal',
      }),
    );
  });

  it('rejects wildcard production CORS', () => {
    assert.throws(() =>
      loadAppConfig({ ...productionValues, CORS_ALLOWED_ORIGINS: '*' }),
    );
  });
});
