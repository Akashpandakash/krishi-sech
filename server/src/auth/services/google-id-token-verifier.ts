import {
  createPublicKey,
  type JsonWebKey,
  type KeyObject,
} from 'node:crypto';

import jwt, { type JwtPayload } from 'jsonwebtoken';

import { AppError } from '../../common/app-error.js';

const certsEndpoint = 'https://www.googleapis.com/oauth2/v3/certs';
// jsonwebtoken types these options as non-empty tuples.
const allowedIssuers: [string, ...string[]] = [
  'https://accounts.google.com',
  'accounts.google.com',
];

/** Extends JsonWebKey so the key object can be handed to createPublicKey. */
interface GoogleJwk extends JsonWebKey {
  kid: string;
  kty: string;
}

export interface GoogleIdentity {
  googleId: string;
  email: string;
  name: string | null;
  profilePhotoUrl: string | null;
}

/**
 * Verifies Google ID tokens against Google's published signing keys.
 *
 * The signature, issuer, audience and expiry are all checked locally, which is
 * why the client is never trusted to report who it is: the token is the only
 * evidence, and an unverified `email` must not create an account.
 */
export class GoogleIdTokenVerifier {
  private keys = new Map<string, KeyObject>();
  private keysExpireAt = 0;
  private pendingRefresh: Promise<void> | null = null;

  constructor(
    private readonly allowedAudiences: string[],
    private readonly requestTimeoutMs = 10_000,
    private readonly fetchImplementation: typeof fetch = fetch,
  ) {}

  get configured(): boolean {
    return this.allowedAudiences.length > 0;
  }

  async verify(idToken: string): Promise<GoogleIdentity> {
    if (!this.configured) {
      throw new AppError(
        503,
        'GOOGLE_LOGIN_UNAVAILABLE',
        'Google sign-in is not configured',
      );
    }
    const payload = await this.verifiedPayload(idToken);

    const googleId = typeof payload.sub === 'string' ? payload.sub : null;
    const email = typeof payload.email === 'string' ? payload.email : null;
    // Google sets this to true or the string "true" depending on the flow.
    const emailVerified =
      payload.email_verified === true || payload.email_verified === 'true';
    if (!googleId || !email || !emailVerified) {
      throw this.rejected();
    }
    return {
      googleId,
      email: email.toLowerCase(),
      name: typeof payload.name === 'string' ? payload.name : null,
      profilePhotoUrl:
        typeof payload.picture === 'string' ? payload.picture : null,
    };
  }

  private async verifiedPayload(idToken: string): Promise<JwtPayload> {
    const keyId = this.keyIdOf(idToken);
    let key = await this.signingKey(keyId);
    if (!key) {
      // Google rotates keys; a miss may simply mean the cache is stale.
      await this.refreshKeys(true);
      key = await this.signingKey(keyId);
    }
    if (!key) throw this.rejected();
    const [audience, ...otherAudiences] = this.allowedAudiences;
    if (audience === undefined) throw this.rejected();
    try {
      const decoded = jwt.verify(idToken, key, {
        algorithms: ['RS256'],
        audience: [audience, ...otherAudiences],
        issuer: allowedIssuers,
      });
      if (typeof decoded === 'string') throw new Error('Unexpected payload');
      return decoded;
    } catch {
      throw this.rejected();
    }
  }

  private keyIdOf(idToken: string): string {
    const header = idToken.split('.')[0];
    if (!header) throw this.rejected();
    try {
      const decoded: unknown = JSON.parse(
        Buffer.from(header, 'base64url').toString('utf8'),
      );
      const kid = (decoded as { kid?: unknown } | null)?.kid;
      if (typeof kid !== 'string') throw new Error('Missing kid');
      return kid;
    } catch {
      throw this.rejected();
    }
  }

  private async signingKey(keyId: string): Promise<KeyObject | undefined> {
    if (Date.now() >= this.keysExpireAt) await this.refreshKeys(false);
    return this.keys.get(keyId);
  }

  private async refreshKeys(force: boolean): Promise<void> {
    if (!force && Date.now() < this.keysExpireAt) return;
    // Collapse concurrent refreshes so a burst of logins fetches once.
    this.pendingRefresh ??= this.fetchKeys().finally(() => {
      this.pendingRefresh = null;
    });
    await this.pendingRefresh;
  }

  private async fetchKeys(): Promise<void> {
    const controller = new AbortController();
    const timeout = setTimeout(
      () => controller.abort(),
      this.requestTimeoutMs,
    );
    try {
      const response = await this.fetchImplementation(certsEndpoint, {
        signal: controller.signal,
      });
      if (!response.ok) throw new Error(`Key fetch failed: ${response.status}`);
      const body = (await response.json()) as { keys?: GoogleJwk[] };
      const keys = new Map<string, KeyObject>();
      for (const jwk of body.keys ?? []) {
        if (jwk.kty !== 'RSA' || !jwk.kid) continue;
        keys.set(jwk.kid, createPublicKey({ key: jwk, format: 'jwk' }));
      }
      if (keys.size === 0) throw new Error('No usable signing keys');
      this.keys = keys;
      this.keysExpireAt = Date.now() + this.cacheTtlMs(response);
    } catch (error) {
      // Keep serving the previous keys if a refresh fails mid-rotation.
      if (this.keys.size === 0) {
        throw new AppError(
          503,
          'GOOGLE_LOGIN_UNAVAILABLE',
          'Google sign-in is temporarily unavailable',
        );
      }
      if (error instanceof AppError) throw error;
    } finally {
      clearTimeout(timeout);
    }
  }

  private cacheTtlMs(response: Response): number {
    const maxAge = /max-age=(\d+)/.exec(
      response.headers.get('cache-control') ?? '',
    )?.[1];
    const seconds = maxAge ? Number.parseInt(maxAge, 10) : Number.NaN;
    if (!Number.isFinite(seconds) || seconds <= 0) return 60 * 60 * 1000;
    return seconds * 1000;
  }

  private rejected(): AppError {
    return new AppError(
      401,
      'GOOGLE_TOKEN_INVALID',
      'Google sign-in could not be verified',
    );
  }
}
