import { AppError } from '../../common/app-error.js';
import type { AuthConfig } from '../../config/auth-config.js';
import type { SmsProvider } from '../providers/sms-provider.js';
import type {
  AuthRefreshToken,
  AuthRepository,
  AuthUser,
} from '../repositories/auth-repository.js';
import { JwtService } from './jwt-service.js';
import { OtpService } from './otp-service.js';

export class AuthService {
  private static readonly demoPhone = '+919999999999';
  private static readonly demoOtp = '123456';

  constructor(
    private readonly repository: AuthRepository,
    private readonly smsProvider: SmsProvider,
    readonly config: AuthConfig,
    readonly jwtService = new JwtService(config),
    private readonly otpService = new OtpService(config.otpHashSecret),
  ) {}

  async sendOtp(
    phone: string,
    developmentClient = false,
    requestId?: string,
  ): Promise<{ debugOtp?: string }> {
    if (this.demoAllowed(phone, developmentClient)) {
      return { debugOtp: AuthService.demoOtp };
    }
    const requestCount = await this.repository.countOtpRequests(
      phone,
      new Date(Date.now() - this.config.otpRequestWindowSeconds * 1000),
    );
    if (requestCount >= this.config.otpMaxRequestsPerWindow) {
      throw new AppError(
        429,
        'OTP_RATE_LIMITED',
        'Too many OTP requests. Please try again later',
      );
    }

    const code = this.otpService.generate();
    await this.repository.createOtp(
      phone,
      this.otpService.hash(code),
      new Date(Date.now() + this.config.otpTtlSeconds * 1000),
    );
    await this.smsProvider.sendOtp(phone, code, requestId);
    return this.config.exposeDebugOtp ? { debugOtp: code } : {};
  }

  async verifyOtp(phone: string, code: string, developmentClient = false) {
    if (
      this.demoAllowed(phone, developmentClient) &&
      code === AuthService.demoOtp
    ) {
      return this.createSession(await this.repository.ensureDemoUser(phone));
    }
    const otp = await this.repository.findLatestOtp(phone);
    if (!otp || otp.expiresAt.getTime() <= Date.now()) {
      throw new AppError(400, 'OTP_EXPIRED', 'OTP is invalid or expired');
    }
    if (otp.attempts >= 5) {
      throw new AppError(429, 'OTP_ATTEMPTS_EXCEEDED', 'Too many OTP attempts');
    }
    if (!this.otpService.matches(code, otp.codeHash)) {
      await this.repository.incrementOtpAttempts(otp.id);
      throw new AppError(400, 'OTP_INVALID', 'OTP is invalid or expired');
    }

    await this.repository.consumeOtp(otp.id);
    let user = await this.repository.findUserByPhone(phone);
    user ??= await this.repository.createUser(phone);
    if (!user.isActive) {
      throw new AppError(403, 'USER_INACTIVE', 'User account is inactive');
    }
    return this.createSession(user);
  }

  async refresh(refreshToken: string) {
    const payload = this.jwtService.verifyRefreshToken(refreshToken);
    const stored = await this.activeRefreshToken(refreshToken);
    if (stored.userId !== payload.sub) {
      throw new AppError(401, 'REFRESH_TOKEN_INVALID', 'Refresh token is invalid');
    }
    const user = await this.repository.findUserById(payload.sub);
    if (!user?.isActive) {
      throw new AppError(401, 'REFRESH_TOKEN_INVALID', 'Refresh token is invalid');
    }
    return this.createSession(user, stored);
  }

  async logout(refreshToken: string): Promise<void> {
    this.jwtService.verifyRefreshToken(refreshToken);
    const stored = await this.activeRefreshToken(refreshToken);
    await this.repository.revokeRefreshToken(stored.id);
  }

  async me(userId: string) {
    const user = await this.repository.findUserById(userId);
    if (!user?.isActive) {
      throw new AppError(404, 'USER_NOT_FOUND', 'User not found');
    }
    return this.publicUser(user);
  }

  private async createSession(user: AuthUser, current?: AuthRefreshToken) {
    const accessToken = this.jwtService.createAccessToken(user);
    const refreshToken = this.jwtService.createRefreshToken(user);
    const tokenHash = this.jwtService.hashRefreshToken(refreshToken);
    const expiresAt = new Date(
      Date.now() + this.config.refreshTokenTtlSeconds * 1000,
    );
    if (current) {
      await this.repository.rotateRefreshToken(
        current.id,
        user.id,
        tokenHash,
        expiresAt,
      );
    } else {
      await this.repository.createRefreshToken(user.id, tokenHash, expiresAt);
    }
    return {
      user: this.publicUser(user),
      accessToken,
      refreshToken,
      expiresIn: this.config.accessTokenTtlSeconds,
    };
  }

  private async activeRefreshToken(token: string): Promise<AuthRefreshToken> {
    const stored = await this.repository.findRefreshToken(
      this.jwtService.hashRefreshToken(token),
    );
    if (
      !stored ||
      stored.revokedAt ||
      stored.expiresAt.getTime() <= Date.now()
    ) {
      throw new AppError(401, 'REFRESH_TOKEN_INVALID', 'Refresh token is invalid');
    }
    return stored;
  }

  private publicUser(user: AuthUser) {
    return {
      id: user.id,
      phone: user.phone,
      name: user.name,
      preferredLanguage: user.preferredLanguage,
      isActive: user.isActive,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }

  private demoAllowed(phone: string, developmentClient: boolean) {
    return (
      this.config.demoLoginEnabled &&
      developmentClient &&
      phone === AuthService.demoPhone
    );
  }
}
