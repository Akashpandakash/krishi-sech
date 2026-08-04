export interface AuthUser {
  id: string;
  phone: string;
  name: string | null;
  preferredLanguage: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface AuthOtp {
  id: string;
  phone: string;
  codeHash: string;
  expiresAt: Date;
  attempts: number;
  consumedAt: Date | null;
}

export interface AuthRefreshToken {
  id: string;
  userId: string;
  tokenHash: string;
  expiresAt: Date;
  revokedAt: Date | null;
}

export interface AuthRepository {
  createOtp(phone: string, codeHash: string, expiresAt: Date): Promise<void>;
  countOtpRequests(phone: string, since: Date): Promise<number>;
  findLatestOtp(phone: string): Promise<AuthOtp | null>;
  incrementOtpAttempts(id: string): Promise<void>;
  consumeOtp(id: string): Promise<void>;
  findUserByPhone(phone: string): Promise<AuthUser | null>;
  findUserById(id: string): Promise<AuthUser | null>;
  createUser(phone: string): Promise<AuthUser>;
  ensureDemoUser(phone: string): Promise<AuthUser>;
  createRefreshToken(
    userId: string,
    tokenHash: string,
    expiresAt: Date,
  ): Promise<void>;
  findRefreshToken(tokenHash: string): Promise<AuthRefreshToken | null>;
  rotateRefreshToken(
    currentTokenId: string,
    userId: string,
    tokenHash: string,
    expiresAt: Date,
  ): Promise<void>;
  revokeRefreshToken(id: string): Promise<void>;
}
