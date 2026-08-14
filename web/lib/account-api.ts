import { ApiError } from './api';

/**
 * The public (unauthenticated) account endpoints.
 *
 * Kept separate from the admin client on purpose: this runs on a page any
 * farmer can open, it must never touch admin tokens, and it must never send
 * an Authorization header.
 */

const API_BASE_URL = (
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000'
).replace(/\/+$/, '');

const ACCOUNT_BASE = `${API_BASE_URL}/api/account`;

/** Per-collection counts of what was erased, shown back as the receipt. */
export interface AccountDeletionSummary {
  crops: number;
  calendarTasks: number;
  farmProfiles: number;
  fertilizerRecommendations: number;
  irrigationRecommendations: number;
  devices: number;
  notificationReceipts: number;
  sessions: number;
}

interface SuccessEnvelope<T> {
  success: true;
  message: string;
  data?: T;
}

interface ErrorEnvelope {
  success: false;
  error: { code: string; message: string };
}

async function post<T>(path: string, body: unknown): Promise<T | undefined> {
  let response: Response;
  try {
    response = await fetch(`${ACCOUNT_BASE}${path}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
  } catch {
    throw new ApiError(
      0,
      'NETWORK_ERROR',
      'Could not reach the server. Check your connection and try again.',
    );
  }

  const text = await response.text();
  if (!text) return undefined;

  let payload: SuccessEnvelope<T> | ErrorEnvelope;
  try {
    payload = JSON.parse(text) as SuccessEnvelope<T> | ErrorEnvelope;
  } catch {
    throw new ApiError(
      response.status,
      'BAD_RESPONSE',
      'The server returned an unexpected response.',
    );
  }

  if (!payload.success) {
    throw new ApiError(response.status, payload.error.code, payload.error.message);
  }
  return payload.data;
}

export const accountApi = {
  /** Step one. `debugOtp` is only ever populated in development builds. */
  sendDeletionOtp: (phone: string) =>
    post<{ debugOtp?: string }>('/deletion/send-otp', { phone }),

  /** Step two. Irreversible — the account is gone when this resolves. */
  confirmDeletion: (phone: string, otp: string, reason?: string) =>
    post<AccountDeletionSummary>('/deletion/confirm', {
      phone,
      otp,
      ...(reason ? { reason } : {}),
    }),
};

/** The API requires E.164. Indian numbers are the common case, so accept a
 *  bare 10-digit number and prefix it rather than rejecting the farmer. */
export function normalizePhone(input: string): string | null {
  const trimmed = input.replace(/[\s()-]/g, '');
  if (/^\+[1-9]\d{7,14}$/.test(trimmed)) return trimmed;
  if (/^[6-9]\d{9}$/.test(trimmed)) return `+91${trimmed}`;
  if (/^0[6-9]\d{9}$/.test(trimmed)) return `+91${trimmed.slice(1)}`;
  return null;
}
