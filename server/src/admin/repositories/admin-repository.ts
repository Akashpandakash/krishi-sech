export const adminRoles = ['owner', 'admin', 'analyst'] as const;
export type AdminRole = (typeof adminRoles)[number];

export interface AdminUser {
  id: string;
  email: string;
  name: string;
  role: AdminRole;
  passwordHash: string;
  isActive: boolean;
  lastLoginAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface AdminSession {
  id: string;
  adminId: string;
  tokenHash: string;
  expiresAt: Date;
  revokedAt: Date | null;
}

export interface AdminUserInput {
  email: string;
  name: string;
  role: AdminRole;
  passwordHash: string;
}

export interface AdminRepository {
  createAdmin(input: AdminUserInput): Promise<AdminUser>;
  findAdminByEmail(email: string): Promise<AdminUser | null>;
  findAdminById(id: string): Promise<AdminUser | null>;
  listAdmins(): Promise<AdminUser[]>;
  countAdmins(): Promise<number>;
  updatePassword(id: string, passwordHash: string): Promise<void>;
  updateAdmin(
    id: string,
    changes: { name?: string; role?: AdminRole; isActive?: boolean },
  ): Promise<AdminUser>;
  recordLogin(id: string, at: Date): Promise<void>;
  createSession(
    adminId: string,
    tokenHash: string,
    expiresAt: Date,
  ): Promise<void>;
  findSession(tokenHash: string): Promise<AdminSession | null>;
  revokeSession(id: string): Promise<void>;
  revokeAllSessions(adminId: string): Promise<void>;
}

/** An admin record without the password hash, safe to return over the API. */
export type PublicAdminUser = Omit<AdminUser, 'passwordHash'>;

export function toPublicAdmin(admin: AdminUser): PublicAdminUser {
  const { passwordHash: _passwordHash, ...rest } = admin;
  return rest;
}
