import type { Request, Response } from 'express';

import { sendSuccess } from '../../common/response.js';
import type { AuthenticatedRequest } from '../middleware/auth-middleware.js';
import type { AuthService } from '../services/auth-service.js';
import {
  googleSignInSchema,
  refreshTokenSchema,
  sendOtpSchema,
  verifyOtpSchema,
} from '../validation/auth-validation.js';

export class AuthController {
  private static readonly developmentHeader = 'x-krishi-development-client';

  constructor(private readonly authService: AuthService) {}

  googleSignIn = async (request: Request, response: Response) => {
    const { idToken } = googleSignInSchema.parse(request.body);
    const session = await this.authService.loginWithGoogle(idToken);
    return sendSuccess(response, 200, 'Signed in successfully', session);
  };

  sendOtp = async (request: Request, response: Response) => {
    const { phone } = sendOtpSchema.parse(request.body);
    const debug = await this.authService.sendOtp(
      phone,
      request.get(AuthController.developmentHeader) === 'true',
      response.locals.requestId,
    );
    return sendSuccess(response, 200, 'OTP sent successfully', debug);
  };

  verifyOtp = async (request: Request, response: Response) => {
    const { phone, otp } = verifyOtpSchema.parse(request.body);
    const session = await this.authService.verifyOtp(
      phone,
      otp,
      request.get(AuthController.developmentHeader) === 'true',
    );
    return sendSuccess(response, 200, 'OTP verified successfully', session);
  };

  refresh = async (request: Request, response: Response) => {
    const { refreshToken } = refreshTokenSchema.parse(request.body);
    const session = await this.authService.refresh(refreshToken);
    return sendSuccess(response, 200, 'Token refreshed successfully', session);
  };

  logout = async (request: Request, response: Response) => {
    const { refreshToken } = refreshTokenSchema.parse(request.body);
    await this.authService.logout(refreshToken);
    return sendSuccess(response, 200, 'Logged out successfully');
  };

  me = async (request: AuthenticatedRequest, response: Response) => {
    const user = await this.authService.me(request.auth!.userId);
    return sendSuccess(response, 200, 'Authenticated user retrieved', user);
  };
}
