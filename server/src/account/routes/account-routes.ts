import { Router } from 'express';
import { z } from 'zod';

import { requireAuth } from '../../auth/middleware/auth-middleware.js';
import type { AuthenticatedRequest } from '../../auth/middleware/auth-middleware.js';
import type { AuthService } from '../../auth/services/auth-service.js';
import { sendSuccess } from '../../common/response.js';
import type { AccountDeletionService } from '../services/account-deletion-service.js';

const phone = z
  .string()
  .trim()
  .regex(/^\+[1-9]\d{7,14}$/, 'Phone number must use E.164 format');
const reason = z.string().trim().max(500).optional();

const requestOtpSchema = z.object({ phone });
const confirmSchema = z.object({
  phone,
  otp: z.string().regex(/^\d{6}$/, 'OTP must contain 6 digits'),
  reason,
});
const inAppDeleteSchema = z.object({ reason }).default({});

/**
 * Play's data-deletion policy needs a route a farmer can complete from the web
 * without installing the app, so the OTP flow stands alone from sign-in.
 */
export function createAccountRouter(
  authService: AuthService,
  deletion: AccountDeletionService,
): Router {
  const router = Router();

  router.post('/deletion/send-otp', async (request, response) => {
    const body = requestOtpSchema.parse(request.body);
    const result = await deletion.requestOtp(
      body.phone,
      response.locals.requestId,
    );
    return sendSuccess(
      response,
      200,
      'Verification code sent to your phone',
      result,
    );
  });

  router.post('/deletion/confirm', async (request, response) => {
    const body = confirmSchema.parse(request.body);
    const outcome = await deletion.confirmWithOtp(
      body.phone,
      body.otp,
      body.reason,
    );
    return sendSuccess(
      response,
      200,
      'Your account and all its data have been deleted',
      outcome.summary,
    );
  });

  router.delete(
    '/',
    requireAuth(authService),
    async (request: AuthenticatedRequest, response) => {
      const body = inAppDeleteSchema.parse(request.body ?? {});
      const outcome = await deletion.deleteAuthenticated(
        request.auth!.userId,
        body.reason,
      );
      return sendSuccess(
        response,
        200,
        'Your account and all its data have been deleted',
        outcome.summary,
      );
    },
  );

  return router;
}
