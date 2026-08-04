import type { SmsProvider } from './sms-provider.js';

export class DummySmsProvider implements SmsProvider {
  private readonly codes = new Map<string, string>();

  async sendOtp(phone: string, code: string): Promise<void> {
    this.codes.set(phone, code);
  }

  lastCodeFor(phone: string): string | undefined {
    return this.codes.get(phone);
  }
}
