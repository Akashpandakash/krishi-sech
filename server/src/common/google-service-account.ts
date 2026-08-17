import jwt from 'jsonwebtoken';

/**
 * Shared Google service-account authorization.
 *
 * The FCM push provider grew its own copy of this flow first; this module is
 * the reusable version for everything that came after (GA4 Data API, BigQuery).
 * Tokens are cached per instance and refreshed a minute before expiry.
 */

export interface GoogleServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
}

const TOKEN_ENDPOINT = 'https://oauth2.googleapis.com/token';

/**
 * Reads a service account from an env var as raw JSON or base64. Base64 is
 * accepted because hosting dashboards routinely mangle multi-line secrets.
 */
export function parseGoogleServiceAccount(
  raw: string | undefined,
  variableName: string,
): GoogleServiceAccount | null {
  const value = raw?.trim();
  if (!value) return null;
  const json = value.startsWith('{')
    ? value
    : Buffer.from(value, 'base64').toString('utf8');

  let parsed: Partial<GoogleServiceAccount>;
  try {
    parsed = JSON.parse(json) as Partial<GoogleServiceAccount>;
  } catch {
    throw new Error(`${variableName} must be service account JSON or base64`);
  }

  if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
    throw new Error(
      `${variableName} must contain project_id, client_email and private_key`,
    );
  }
  return {
    project_id: parsed.project_id,
    client_email: parsed.client_email,
    // Dashboard-pasted keys keep literal \n rather than real newlines.
    private_key: parsed.private_key.replace(/\\n/g, '\n'),
  };
}

export class GoogleAccessTokenProvider {
  private cached: { value: string; expiresAt: number } | null = null;
  private inFlight: Promise<string> | null = null;

  constructor(
    private readonly serviceAccount: GoogleServiceAccount,
    private readonly scope: string,
    private readonly timeoutMs = 20_000,
    private readonly fetchImplementation: typeof fetch = fetch,
  ) {}

  /** Returns a valid access token, minting one only when necessary. */
  async get(): Promise<string> {
    if (this.cached && this.cached.expiresAt > Date.now() + 60_000) {
      return this.cached.value;
    }
    // Single-flight: concurrent callers share one token exchange rather than
    // each burning a JWT assertion against the same quota.
    this.inFlight ??= this.mint().finally(() => {
      this.inFlight = null;
    });
    return this.inFlight;
  }

  private async mint(): Promise<string> {
    const issuedAt = Math.floor(Date.now() / 1000);
    const assertion = jwt.sign(
      {
        iss: this.serviceAccount.client_email,
        scope: this.scope,
        aud: TOKEN_ENDPOINT,
        iat: issuedAt,
        exp: issuedAt + 3600,
      },
      this.serviceAccount.private_key,
      { algorithm: 'RS256' },
    );

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    let response: Response;
    try {
      response = await this.fetchImplementation(TOKEN_ENDPOINT, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
        body: new URLSearchParams({
          grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          assertion,
        }).toString(),
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timer);
    }

    if (!response.ok) {
      throw new Error(
        `Google authorization failed with ${response.status}. Check that the service account key is valid and that the API is enabled.`,
      );
    }
    const payload = (await response.json()) as {
      access_token: string;
      expires_in: number;
    };
    this.cached = {
      value: payload.access_token,
      expiresAt: Date.now() + payload.expires_in * 1000,
    };
    return payload.access_token;
  }
}

/** POSTs JSON to a Google API with a bearer token and a hard timeout. */
export async function googleApiPost<T>(
  url: string,
  body: unknown,
  options: {
    tokens: GoogleAccessTokenProvider;
    timeoutMs?: number;
    fetchImplementation?: typeof fetch;
    apiName: string;
  },
): Promise<T> {
  const {
    tokens,
    timeoutMs = 20_000,
    fetchImplementation = fetch,
    apiName,
  } = options;
  const token = await tokens.get();
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  let response: Response;
  try {
    response = await fetchImplementation(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
  } catch (error) {
    throw new Error(
      `${apiName} request failed: ${
        error instanceof Error ? error.message : String(error)
      }`,
    );
  } finally {
    clearTimeout(timer);
  }

  if (!response.ok) {
    // Google's error bodies carry the actionable part (missing role, API not
    // enabled, wrong property id), so surface it rather than just the status.
    const detail = await response.text().catch(() => '');
    let message = detail.slice(0, 400);
    try {
      const parsed = JSON.parse(detail) as { error?: { message?: string } };
      if (parsed.error?.message) message = parsed.error.message;
    } catch {
      // keep the raw snippet
    }
    throw new Error(`${apiName} returned ${response.status}: ${message}`);
  }
  return (await response.json()) as T;
}
