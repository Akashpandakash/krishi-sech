export interface SmsProvider {
  sendOtp(phone: string, code: string, requestId?: string): Promise<void>;
}
