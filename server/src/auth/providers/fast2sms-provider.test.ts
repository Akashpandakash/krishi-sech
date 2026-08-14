import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { AppError } from '../../common/app-error.js';
import { Fast2SmsProvider } from './fast2sms-provider.js';

const config = {
  apiKey: 'test-api-key',
  senderId: 'KRISHI',
  route: 'otp',
  requestTimeoutMs: 1_000,
};

describe('Fast2SMS provider', () => {
  it('sends an OTP without logging the phone, OTP, or API key', async () => {
    let capturedRequest: RequestInit | undefined;
    const logs: string[] = [];
    const provider = new Fast2SmsProvider(
      config,
      async (_url, request) => {
        capturedRequest = request;
        return new Response(JSON.stringify({ return: true }), { status: 200 });
      },
      async () => {},
      true,
      (message) => logs.push(message),
    );

    await provider.sendOtp('+919876543210', '654321', 'request-id-1234');

    assert.equal(capturedRequest?.method, 'POST');
    assert.equal(
      (capturedRequest?.headers as Record<string, string>).Authorization,
      config.apiKey,
    );
    const payload = JSON.parse(String(capturedRequest?.body));
    assert.deepEqual(payload, {
      route: 'otp',
      sender_id: 'KRISHI',
      variables_values: '654321',
      numbers: '9876543210',
    });
    assert.deepEqual(logs, [JSON.stringify({ requestId: 'request-id-1234' })]);
    assert.doesNotMatch(logs[0], /9876543210|654321|test-api-key/);
  });

  it('retries one transient provider failure and then succeeds', async () => {
    let calls = 0;
    let delays = 0;
    const provider = new Fast2SmsProvider(
      config,
      async () => {
        calls += 1;
        return calls === 1
          ? new Response('{}', { status: 503 })
          : new Response(JSON.stringify({ return: true }), { status: 200 });
      },
      async () => {
        delays += 1;
      },
    );

    await provider.sendOtp('+919876543210', '654321');
    assert.equal(calls, 2);
    assert.equal(delays, 1);
  });

  it('does not retry authentication errors and returns a safe error', async () => {
    let calls = 0;
    const provider = new Fast2SmsProvider(config, async () => {
      calls += 1;
      return new Response(JSON.stringify({ status_code: 412 }), {
        status: 401,
      });
    });

    await assert.rejects(
      provider.sendOtp('+919876543210', '654321'),
      (error: unknown) => {
        assert.ok(error instanceof AppError);
        assert.equal(error.code, 'SMS_AUTHENTICATION_FAILED');
        assert.doesNotMatch(error.message, /test-api-key|9876543210|654321/);
        return true;
      },
    );
    assert.equal(calls, 1);
  });

  it('retries a network failure once and reports provider unavailability', async () => {
    let calls = 0;
    const provider = new Fast2SmsProvider(
      config,
      async () => {
        calls += 1;
        throw new TypeError('network unavailable');
      },
      async () => {},
    );

    await assert.rejects(
      provider.sendOtp('+919876543210', '654321'),
      (error: unknown) => {
        assert.ok(error instanceof AppError);
        assert.equal(error.code, 'SMS_PROVIDER_UNAVAILABLE');
        return true;
      },
    );
    assert.equal(calls, 2);
  });
});
