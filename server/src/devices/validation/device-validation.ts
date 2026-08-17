import { z } from 'zod';

import { devicePlatforms } from '../repositories/device-repository.js';

/**
 * FCM registration tokens have no published format or fixed length, so the
 * bound only rejects obvious junk and oversized bodies.
 */
export const registerDeviceSchema = z.object({
  token: z.string().trim().min(32).max(4096),
  platform: z.enum(devicePlatforms),
});

export const unregisterDeviceSchema = z.object({
  token: z.string().trim().min(32).max(4096),
});
