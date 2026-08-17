export interface AuthUser {
  id: string;
  /** Null for accounts created through Google sign-in. */
  phone: string | null;
  email: string | null;
  googleId: string | null;
  name: string | null;
  preferredLanguage: string;
  profilePhotoUrl?: string | null;
  state?: string | null;
  district?: string | null;
  village?: string | null;
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

export interface GoogleUserInput {
  googleId: string;
  email: string;
  name: string | null;
  profilePhotoUrl: string | null;
}

export interface AuthRepository {
  findUserByGoogleId(googleId: string): Promise<AuthUser | null>;
  createGoogleUser(input: GoogleUserInput): Promise<AuthUser>;
  createOtp(phone: string, codeHash: string, expiresAt: Date): Promise<void>;
  countOtpRequests(phone: string, since: Date): Promise<number>;
  findLatestOtp(phone: string): Promise<AuthOtp | null>;
  incrementOtpAttempts(id: string): Promise<void>;
  consumeOtp(id: string): Promise<void>;
  findUserByPhone(phone: string): Promise<AuthUser | null>;
  findUserById(id: string): Promise<AuthUser | null>;
  createUser(phone: string): Promise<AuthUser>;
  ensureDemoUser(phone: string): Promise<AuthUser>;
  /** Erases the account record itself; owned data is removed by its own repository. */
  deleteUser(id: string): Promise<void>;
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
