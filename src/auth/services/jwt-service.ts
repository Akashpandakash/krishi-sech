import { createHash, randomUUID } from 'node:crypto';

import jwt, { type JwtPayload } from 'jsonwebtoken';

import { AppError } from '../../common/app-error.js';
import type { AuthConfig } from '../../config/auth-config.js';
import type { AuthUser } from '../repositories/auth-repository.js';

export interface AuthTokenPayload extends JwtPayload {
  sub: string;
  phone: string;
  type: 'access' | 'refresh';
}

export class JwtService {
  constructor(private readonly config: AuthConfig) {}

  createAccessToken(user: AuthUser): string {
    return jwt.sign(
      { phone: user.phone, type: 'access' },
      this.config.accessTokenSecret,
      {
        subject: user.id,
        jwtid: randomUUID(),
        expiresIn: this.config.accessTokenTtlSeconds,
      },
    );
  }

  createRefreshToken(user: AuthUser): string {
    return jwt.sign(
      { phone: user.phone, type: 'refresh' },
      this.config.refreshTokenSecret,
      {
        subject: user.id,
        jwtid: randomUUID(),
        expiresIn: this.config.refreshTokenTtlSeconds,
      },
    );
  }

  verifyAccessToken(token: string): AuthTokenPayload {
    return this.verify(token, this.config.accessTokenSecret, 'access');
  }

  verifyRefreshToken(token: string): AuthTokenPayload {
    return this.verify(token, this.config.refreshTokenSecret, 'refresh');
  }

  hashRefreshToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  private verify(
    token: string,
    secret: string,
    type: AuthTokenPayload['type'],
  ): AuthTokenPayload {
    try {
      const decoded = jwt.verify(token, secret);
      if (
        typeof decoded === 'string' ||
        typeof decoded.sub !== 'string' ||
        decoded.type !== type ||
        typeof decoded.phone !== 'string'
      ) {
        throw new Error('Invalid token payload');
      }
      return decoded as AuthTokenPayload;
    } catch {
      throw new AppError(401, 'TOKEN_INVALID', 'Token is invalid or expired');
    }
  }
}
