'use client';

import { useState } from 'react';

import {
  accountApi,
  normalizePhone,
  type AccountDeletionSummary,
} from '@/lib/account-api';
import { ApiError } from '@/lib/api';

type Stage = 'phone' | 'code' | 'done';

const SUMMARY_LABELS: [keyof AccountDeletionSummary, string][] = [
  ['crops', 'Crops'],
  ['calendarTasks', 'Calendar tasks'],
  ['farmProfiles', 'Farm profiles'],
  ['fertilizerRecommendations', 'Fertilizer recommendations'],
  ['irrigationRecommendations', 'Irrigation recommendations'],
  ['devices', 'Registered devices'],
  ['notificationReceipts', 'Notification records'],
  ['sessions', 'Sign-in sessions'],
];

function describe(error: unknown): string {
  if (error instanceof ApiError) return error.message;
  if (error instanceof Error) return error.message;
  return 'Something went wrong. Please try again.';
}

export function DeleteAccountFlow() {
  const [stage, setStage] = useState<Stage>('phone');
  const [phoneInput, setPhoneInput] = useState('');
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [reason, setReason] = useState('');
  const [acknowledged, setAcknowledged] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [debugOtp, setDebugOtp] = useState<string | null>(null);
  const [summary, setSummary] = useState<AccountDeletionSummary | null>(null);

  const sendCode = async (event: React.FormEvent) => {
    event.preventDefault();
    const normalized = normalizePhone(phoneInput);
    if (!normalized) {
      setError(
        'Enter the phone number on your account — a 10-digit Indian mobile number, or an international number starting with +.',
      );
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const result = await accountApi.sendDeletionOtp(normalized);
      setPhone(normalized);
      setDebugOtp(result?.debugOtp ?? null);
      setStage('code');
    } catch (caught) {
      setError(describe(caught));
    } finally {
      setBusy(false);
    }
  };

  const confirm = async (event: React.FormEvent) => {
    event.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const result = await accountApi.confirmDeletion(
        phone,
        otp,
        reason.trim() || undefined,
      );
      setSummary(result ?? null);
      setStage('done');
    } catch (caught) {
      setError(describe(caught));
    } finally {
      setBusy(false);
    }
  };

  if (stage === 'done') {
    return (
      <section className="glass glass--strong panel stack delete-flow" aria-live="polite">
        <h2 className="h3">Your account has been deleted</h2>
        <p className="notice notice--success">
          Everything stored against {phone} has been permanently erased. You can
          close this page.
        </p>
        {summary ? (
          <>
            <p className="muted">Records removed:</p>
            <ul className="delete-flow__summary">
              {SUMMARY_LABELS.map(([key, label]) => (
                <li key={key} className="spread">
                  <span>{label}</span>
                  <strong className="numeric">{summary[key]}</strong>
                </li>
              ))}
            </ul>
          </>
        ) : null}
        <p className="muted delete-flow__note">
          If you install {'Krishi Sech'} again you will start with a completely
          new account.
        </p>
      </section>
    );
  }

  return (
    <section className="glass glass--strong panel stack delete-flow">
      {error ? (
        <p className="notice notice--error" role="alert">
          {error}
        </p>
      ) : null}

      {stage === 'phone' ? (
        <form className="stack" onSubmit={sendCode}>
          <div className="field">
            <label htmlFor="del-phone">Phone number on your account</label>
            <input
              id="del-phone"
              className="input"
              type="tel"
              inputMode="tel"
              autoComplete="tel"
              required
              placeholder="98765 43210"
              value={phoneInput}
              onChange={(event) => setPhoneInput(event.target.value)}
            />
            <span className="muted delete-flow__hint">
              Indian mobile numbers can be entered without +91.
            </span>
          </div>
          <div>
            <button className="btn btn--primary" type="submit" disabled={busy}>
              {busy ? 'Sending code…' : 'Send verification code'}
            </button>
          </div>
        </form>
      ) : (
        <form className="stack" onSubmit={confirm}>
          <p className="muted">
            We sent a 6-digit code to <strong>{phone}</strong>.{' '}
            <button
              type="button"
              className="btn btn--ghost btn--sm"
              onClick={() => {
                setStage('phone');
                setOtp('');
                setError(null);
                setDebugOtp(null);
              }}
            >
              Use a different number
            </button>
          </p>

          {/* Development builds return the code so the flow is testable
              without an SMS provider. Never populated in production. */}
          {debugOtp ? (
            <p className="notice notice--info">
              Development build — your code is <strong>{debugOtp}</strong>.
            </p>
          ) : null}

          <div className="field">
            <label htmlFor="del-otp">6-digit code</label>
            <input
              id="del-otp"
              className="input"
              inputMode="numeric"
              autoComplete="one-time-code"
              required
              pattern="\d{6}"
              maxLength={6}
              placeholder="000000"
              value={otp}
              onChange={(event) =>
                setOtp(event.target.value.replace(/\D/g, '').slice(0, 6))
              }
            />
          </div>

          <div className="field">
            <label htmlFor="del-reason">
              Why are you leaving? (optional, helps us improve)
            </label>
            <textarea
              id="del-reason"
              className="input"
              maxLength={500}
              value={reason}
              onChange={(event) => setReason(event.target.value)}
            />
          </div>

          <label className="delete-flow__confirm">
            <input
              type="checkbox"
              checked={acknowledged}
              onChange={(event) => setAcknowledged(event.target.checked)}
            />
            <span>
              I understand this permanently deletes my account, my farm profile,
              my crops and my calendar, and that it cannot be undone.
            </span>
          </label>

          <div>
            <button
              className="btn btn--danger"
              type="submit"
              disabled={busy || !acknowledged || otp.length !== 6}
            >
              {busy ? 'Deleting…' : 'Permanently delete my account'}
            </button>
          </div>
        </form>
      )}
    </section>
  );
}
