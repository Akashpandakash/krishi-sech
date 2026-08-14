'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useState } from 'react';

import { useAuth } from './auth-context';
import { describeError } from './use-async';
import { isOwner } from '@/lib/types';

const NAV = [
  { href: '/admin', label: 'Dashboard', exact: true },
  { href: '/admin/users', label: 'Farmers', exact: false },
  { href: '/admin/mandi', label: 'Mandi prices', exact: false },
  { href: '/admin/market', label: 'Market catalogue', exact: false },
  { href: '/admin/telemetry', label: 'App health', exact: false },
  { href: '/admin/broadcasts', label: 'Broadcasts', exact: false },
  { href: '/admin/audit', label: 'Audit log', exact: false },
  { href: '/admin/admins', label: 'Admin accounts', exact: false, ownerOnly: true },
];

function SignInScreen() {
  const { signIn } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await signIn(email, password);
    } catch (caught) {
      setError(describeError(caught));
    } finally {
      setBusy(false);
    }
  };

  return (
    <main className="auth-screen">
      <div className="glass glass--strong auth-card">
        <div className="stack">
          <div className="row">
            <span className="admin__mark" aria-hidden="true">
              KS
            </span>
            <div>
              <h1 className="h3">Krishi Sech admin</h1>
              <p className="muted" style={{ fontSize: '0.8125rem' }}>
                Sign in to manage farmers and broadcasts
              </p>
            </div>
          </div>

          <form className="stack" onSubmit={submit}>
            {error ? (
              <p className="notice notice--error" role="alert">
                {error}
              </p>
            ) : null}

            <div className="field">
              <label htmlFor="admin-email">Email</label>
              <input
                id="admin-email"
                className="input"
                type="email"
                autoComplete="username"
                required
                value={email}
                onChange={(event) => setEmail(event.target.value)}
              />
            </div>

            <div className="field">
              <label htmlFor="admin-password">Password</label>
              <input
                id="admin-password"
                className="input"
                type="password"
                autoComplete="current-password"
                required
                value={password}
                onChange={(event) => setPassword(event.target.value)}
              />
            </div>

            <button className="btn btn--primary" type="submit" disabled={busy}>
              {busy ? 'Signing in…' : 'Sign in'}
            </button>
          </form>

          <p className="muted" style={{ fontSize: '0.75rem' }}>
            Accounts are created with <code>npm run admin:create</code> in the
            server workspace. Five failed attempts locks the account.
          </p>
        </div>
      </div>
    </main>
  );
}

export function AdminShell({ children }: { children: React.ReactNode }) {
  const { admin, loading, signOut } = useAuth();
  const pathname = usePathname();

  if (loading) {
    return (
      <main className="auth-screen">
        <div className="glass auth-card">
          <div className="stack" aria-busy="true">
            <div className="skeleton" style={{ height: 22, width: '55%' }} />
            <div className="skeleton" style={{ height: 14, width: '80%' }} />
            <div className="skeleton" style={{ height: 14, width: '70%' }} />
            <span className="sr-only">Restoring your session…</span>
          </div>
        </div>
      </main>
    );
  }

  if (!admin) return <SignInScreen />;

  const links = NAV.filter((item) => !item.ownerOnly || isOwner(admin.role));

  return (
    <div className="admin">
      <a className="skip-link" href="#admin-content">
        Skip to content
      </a>

      <aside className="glass admin__sidebar">
        <Link className="admin__brand" href="/admin">
          <span className="admin__mark" aria-hidden="true">
            KS
          </span>
          Krishi Sech
        </Link>

        <nav className="admin__nav" aria-label="Admin sections">
          {links.map((item) => {
            const active = item.exact
              ? pathname === item.href
              : pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className="admin__link"
                aria-current={active ? 'page' : undefined}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>

        <p className="muted" style={{ fontSize: '0.75rem', marginTop: 'auto' }}>
          Signed in as <strong>{admin.role}</strong>.
          {admin.role === 'analyst'
            ? ' Analysts have read-only access.'
            : null}
        </p>
      </aside>

      <div className="admin__main">
        <header className="glass admin__topbar">
          <div>
            <p className="eyebrow">Krishi Sech</p>
            <p style={{ fontWeight: 600 }}>Administration</p>
          </div>
          <div className="row">
            <div className="admin__identity">
              <strong>{admin.name}</strong>
              <span className="muted" style={{ fontSize: '0.75rem' }}>
                {admin.email}
              </span>
            </div>
            <button className="btn btn--glass btn--sm" onClick={signOut}>
              Sign out
            </button>
          </div>
        </header>

        <main id="admin-content" className="admin__main">
          {children}
        </main>
      </div>
    </div>
  );
}
