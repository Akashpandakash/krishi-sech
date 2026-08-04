import { createHmac, randomInt, timingSafeEqual } from 'node:crypto';

export class OtpService {
  constructor(private readonly hashSecret: string) {}

  generate(): string {
    return randomInt(0, 1_000_000).toString().padStart(6, '0');
  }

  hash(code: string): string {
    return createHmac('sha256', this.hashSecret).update(code).digest('hex');
  }

  matches(code: string, expectedHash: string): boolean {
    const received = Buffer.from(this.hash(code), 'hex');
    const expected = Buffer.from(expectedHash, 'hex');
    return (
      received.length === expected.length && timingSafeEqual(received, expected)
    );
  }
}
