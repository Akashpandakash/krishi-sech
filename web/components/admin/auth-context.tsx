'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from 'react';

import { adminApi, onForcedSignOut, tokenStore } from '@/lib/api';
import type { PublicAdminUser } from '@/lib/types';

interface AuthState {
  admin: PublicAdminUser | null;
  /** True until the stored token has been checked against /auth/me. */
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthState | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [admin, setAdmin] = useState<PublicAdminUser | null>(null);
  const [loading, setLoading] = useState(true);

  // Restore the session on first paint. A stored access token proves nothing
  // on its own — only /auth/me confirms it is still valid and un-revoked.
  useEffect(() => {
    let cancelled = false;
    (async () => {
      if (!tokenStore.access && !tokenStore.refresh) {
        if (!cancelled) setLoading(false);
        return;
      }
      try {
        const current = await adminApi.me();
        if (!cancelled) setAdmin(current);
      } catch {
        tokenStore.clear();
        if (!cancelled) setAdmin(null);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  // The API client fires this when a refresh fails anywhere in the app.
  useEffect(() => onForcedSignOut(() => setAdmin(null)), []);

  const signIn = useCallback(async (email: string, password: string) => {
    const session = await adminApi.login(email, password);
    setAdmin(session.admin);
  }, []);

  const signOut = useCallback(async () => {
    await adminApi.logout();
    setAdmin(null);
  }, []);

  const value = useMemo(
    () => ({ admin, loading, signIn, signOut }),
    [admin, loading, signIn, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthState {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used inside an AuthProvider');
  }
  return context;
}
