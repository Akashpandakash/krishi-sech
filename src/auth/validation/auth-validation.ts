import { z } from 'zod';

const phone = z
  .string()
  .trim()
  .regex(/^\+[1-9]\d{7,14}$/, 'Phone number must use E.164 format');

export const sendOtpSchema = z.object({ phone });
export const verifyOtpSchema = z.object({
  phone,
  otp: z.string().regex(/^\d{6}$/, 'OTP must contain 6 digits'),
});
export const refreshTokenSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token is required'),
});
