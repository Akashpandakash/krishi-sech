import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { loadAppConfig } from './app-config.js';
import { loadFast2SmsConfig } from './fast2sms-config.js';
import { DummySmsProvider } from '../auth/providers/dummy-sms-provider.js';
import { Fast2SmsProvider } from '../auth/providers/fast2sms-provider.js';
import { createSmsProvider } from '../auth/providers/sms-provider-factory.js';

describe('Fast2SMS configuration', () => {
  it('requires all provider values outside development', () => {
    assert.throws(() => loadFast2SmsConfig({}), /FAST2SMS_SENDER_ID/);
    assert.throws(
      () =>
        loadFast2SmsConfig({
          FAST2SMS_SENDER_ID: 'KRISHI',
          FAST2SMS_ROUTE: 'otp',
        }),
      /FAST2SMS_API_KEY/,
    );
  });

  it('selects DummySmsProvider only in development', () => {
    const development = loadAppConfig({
      APP_ENV: 'development',
      LOGGING_ENABLED: 'false',
    });
    assert.ok(createSmsProvider(development, {}) instanceof DummySmsProvider);

    const production = loadAppConfig({
      APP_ENV: 'production',
      LOGGING_ENABLED: 'false',
      DEMO_LOGIN_ENABLED: 'false',
      DEBUG_OTP_ENABLED: 'false',
      OPENAI_ENABLED: 'false',
    });
    const provider = createSmsProvider(production, {
      FAST2SMS_API_KEY: 'test-api-key',
      FAST2SMS_SENDER_ID: 'KRISHI',
      FAST2SMS_ROUTE: 'otp',
    });
    assert.ok(provider instanceof Fast2SmsProvider);

    const staging = loadAppConfig({
      APP_ENV: 'staging',
      LOGGING_ENABLED: 'false',
      DEMO_LOGIN_ENABLED: 'false',
      DEBUG_OTP_ENABLED: 'false',
      OPENAI_ENABLED: 'false',
    });
    const stagingProvider = createSmsProvider(staging, {
      FAST2SMS_API_KEY: 'test-api-key',
      FAST2SMS_SENDER_ID: 'KRISHI',
      FAST2SMS_ROUTE: 'otp',
    });
    assert.ok(stagingProvider instanceof Fast2SmsProvider);
    assert.ok(!(stagingProvider instanceof DummySmsProvider));
  });
});
