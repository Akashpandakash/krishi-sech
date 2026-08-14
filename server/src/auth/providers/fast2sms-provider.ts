import { AppError } from '../../common/app-error.js';
import type { Fast2SmsConfig } from '../../config/fast2sms-config.js';
import type { SmsProvider } from './sms-provider.js';

type FetchFunction = (
  input: string | URL | Request,
  init?: RequestInit,
) => Promise<Response>;
type DelayFunction = (milliseconds: number) => Promise<void>;

interface Fast2SmsResponse {
  return?: boolean;
  status_code?: number;
}

export class Fast2SmsProvider implements SmsProvider {
  private static readonly endpoint = 'https://www.fast2sms.com/dev/bulkV2';

  constructor(
    private readonly config: Fast2SmsConfig,
    private readonly fetchFunction: FetchFunction = fetch,
    private readonly delay: DelayFunction = (milliseconds) =>
      new Promise((resolve) => setTimeout(resolve, milliseconds)),
    private readonly production = false,
    private readonly log: (message: string) => void = console.info,
  ) {}

  async sendOtp(phone: string, code: string, requestId?: string): Promise<void> {
    const mobile = this.indianMobileNumber(phone);

    for (let attempt = 0; attempt < 2; attempt += 1) {
      try {
        const response = await this.deliver(mobile, code);
        const body = await this.safeBody(response);
        if (response.ok && body.return !== false) {
          this.logRequestId(requestId);
          return;
        }
        const error = this.providerError(response.status, body.status_code);
        if (!this.transient(response.status) || attempt === 1) {
          this.logRequestId(requestId);
          throw error;
        }
      } catch (error) {
        if (error instanceof AppError) throw error;
        if (attempt === 1) break;
      }
      await this.delay(250);
    }

    this.logRequestId(requestId);
    throw new AppError(
      503,
      'SMS_PROVIDER_UNAVAILABLE',
      'OTP delivery is temporarily unavailable',
    );
  }

  private async deliver(mobile: string, code: string): Promise<Response> {
    const controller = new AbortController();
    const timeout = setTimeout(
      () => controller.abort(),
      this.config.requestTimeoutMs,
    );
    try {
      return await this.fetchFunction(Fast2SmsProvider.endpoint, {
        method: 'POST',
        headers: {
          Accept: 'application/json',
          Authorization: this.config.apiKey,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          route: this.config.route,
          sender_id: this.config.senderId,
          variables_values: code,
          numbers: mobile,
        }),
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timeout);
    }
  }

  private async safeBody(response: Response): Promise<Fast2SmsResponse> {
    try {
      const value: unknown = await response.json();
      if (value && typeof value === 'object') {
        return value as Fast2SmsResponse;
      }
    } catch {
      // The HTTP status still provides a safe error classification.
    }
    return {};
  }

  private providerError(httpStatus: number, providerCode?: number): AppError {
    if (httpStatus === 401 || providerCode === 412 || providerCode === 413) {
      return new AppError(
        502,
        'SMS_AUTHENTICATION_FAILED',
        'OTP delivery configuration is unavailable',
      );
    }
    if (providerCode === 416) {
      return new AppError(
        503,
        'SMS_QUOTA_EXHAUSTED',
        'OTP delivery is temporarily unavailable',
      );
    }
    if (httpStatus === 429) {
      return new AppError(
        503,
        'SMS_RATE_LIMITED',
        'OTP delivery is temporarily unavailable',
      );
    }
    return new AppError(
      httpStatus >= 500 ? 503 : 502,
      httpStatus >= 500 ? 'SMS_PROVIDER_UNAVAILABLE' : 'SMS_DELIVERY_FAILED',
      'OTP delivery failed. Please try again',
    );
  }

  private transient(status: number): boolean {
    return status === 429 || status >= 500;
  }

  private indianMobileNumber(phone: string): string {
    const match = /^\+91([6-9]\d{9})$/.exec(phone);
    if (!match) {
      throw new AppError(400, 'PHONE_INVALID', 'Phone number is invalid');
    }
    return match[1];
  }

  private logRequestId(requestId?: string): void {
    if (this.production && requestId) {
      this.log(JSON.stringify({ requestId }));
    }
  }
}
