import {
  cert,
  deleteApp,
  getApps,
  initializeApp,
  type App,
} from 'firebase-admin/app';
import { getMessaging, type BatchResponse } from 'firebase-admin/messaging';

import type {
  PushDeliveryProvider,
  PushDeliveryResult,
  PushMessage,
} from './push-delivery-provider.js';

export interface FcmServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

/**
 * FCM accepts at most 500 tokens per multicast call. The Admin SDK does not
 * split for us, so a broadcast to a large audience is chunked here.
 */
const MULTICAST_LIMIT = 500;

/** A named app, so initializing this provider never collides with any other
 *  Firebase app the process might create. */
const APP_NAME = 'krishi-sech-push';

/**
 * Error codes that mean the token is permanently dead rather than temporarily
 * unreachable. Anything else (quota, unavailable, internal) is retryable and
 * must NOT delete the registration, or a transient FCM outage would silently
 * unsubscribe the entire audience.
 */
const STALE_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
  'messaging/invalid-argument',
]);

/**
 * Reads the service account from `FCM_SERVICE_ACCOUNT` as raw JSON or base64
 * (base64 survives dashboards that mangle multi-line secrets).
 */
export function parseServiceAccount(
  raw: string | undefined,
): FcmServiceAccount | null {
  const value = raw?.trim();
  if (!value) return null;
  const json = value.startsWith('{')
    ? value
    : Buffer.from(value, 'base64').toString('utf8');
  const parsed = JSON.parse(json) as Partial<FcmServiceAccount>;
  if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
    throw new Error(
      'FCM_SERVICE_ACCOUNT must contain project_id, client_email and private_key',
    );
  }
  return {
    project_id: parsed.project_id,
    client_email: parsed.client_email,
    // Dashboard-pasted keys keep literal \n rather than real newlines.
    private_key: parsed.private_key.replace(/\\n/g, '\n'),
  };
}

export class FcmPushDeliveryProvider implements PushDeliveryProvider {
  readonly name = 'fcm';
  readonly configured = true;

  private readonly app: App;

  constructor(serviceAccount: FcmServiceAccount) {
    const existing = getApps().find((app) => app.name === APP_NAME);
    this.app =
      existing ??
      initializeApp(
        {
          credential: cert({
            projectId: serviceAccount.project_id,
            clientEmail: serviceAccount.client_email,
            privateKey: serviceAccount.private_key,
          }),
          projectId: serviceAccount.project_id,
        },
        APP_NAME,
      );
  }

  async send(
    tokens: string[],
    message: PushMessage,
  ): Promise<PushDeliveryResult> {
    if (tokens.length === 0) {
      return { delivered: 0, failed: 0, staleTokens: [], failureReason: null };
    }

    const messaging = getMessaging(this.app);
    let delivered = 0;
    let failed = 0;
    const staleTokens: string[] = [];
    let failureReason: string | null = null;

    for (let index = 0; index < tokens.length; index += MULTICAST_LIMIT) {
      const batch = tokens.slice(index, index + MULTICAST_LIMIT);

      let response: BatchResponse;
      try {
        response = await messaging.sendEachForMulticast({
          tokens: batch,
          notification: { title: message.title, body: message.body },
          data: message.data,
          android: { priority: 'high' },
          apns: {
            payload: { aps: { sound: 'default' } },
          },
        });
      } catch (error) {
        // A whole-batch failure is an auth or transport problem, not a token
        // problem, so nothing is marked stale.
        failed += batch.length;
        failureReason ??=
          error instanceof Error ? error.message : 'FCM send failed';
        continue;
      }

      delivered += response.successCount;
      failed += response.failureCount;

      response.responses.forEach((result, position) => {
        if (result.success) return;
        const code = result.error?.code ?? 'unknown';
        failureReason ??= `${code}: ${result.error?.message ?? 'send failed'}`;
        if (STALE_TOKEN_CODES.has(code)) {
          const token = batch[position];
          if (token) staleTokens.push(token);
        }
      });
    }

    return { delivered, failed, staleTokens, failureReason };
  }

  /** Releases the Admin SDK app; used by tests and graceful shutdown. */
  async close(): Promise<void> {
    await deleteApp(this.app);
  }
}
