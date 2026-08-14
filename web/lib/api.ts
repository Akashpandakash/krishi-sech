import type {
  ActivityEntry,
  AnalyticsResponse,
  CrashResponse,
  AdminRole,
  AdminSessionResponse,
  AdminUserDetail,
  Broadcast,
  BroadcastAnalytics,
  BroadcastAudience,
  BroadcastCategory,
  BroadcastStatus,
  AuditLogEntry,
  DistributionMetrics,
  FilterOptions,
  GrowthMetrics,
  MandiFilterOptions,
  MandiPriceInput,
  MandiPriceRecord,
  MandiSource,
  MarketProduct,
  MarketProductInput,
  MetricsSource,
  OverviewMetrics,
  PublicAdminUser,
  PushTransport,
  UserListResult,
  UserSort,
  UserStatusFilter,
} from './types';

const API_BASE_URL = (
  process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000'
).replace(/\/+$/, '');

const ADMIN_BASE = `${API_BASE_URL}/api/admin`;

const ACCESS_KEY = 'krishi.admin.access';
const REFRESH_KEY = 'krishi.admin.refresh';

/** Envelope every endpoint returns on success. */
interface SuccessEnvelope<T> {
  success: true;
  message: string;
  data?: T;
}

interface ErrorEnvelope {
  success: false;
  error: {
    code: string;
    message: string;
    details?: { path: string; message: string }[];
  };
  requestId?: string;
}

export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly details?: { path: string; message: string }[],
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

/* ------------------------------------------------------------ token store */

export const tokenStore = {
  get access(): string | null {
    if (typeof window === 'undefined') return null;
    return window.localStorage.getItem(ACCESS_KEY);
  },
  get refresh(): string | null {
    if (typeof window === 'undefined') return null;
    return window.localStorage.getItem(REFRESH_KEY);
  },
  save(session: { accessToken: string; refreshToken: string }): void {
    if (typeof window === 'undefined') return;
    window.localStorage.setItem(ACCESS_KEY, session.accessToken);
    window.localStorage.setItem(REFRESH_KEY, session.refreshToken);
  },
  clear(): void {
    if (typeof window === 'undefined') return;
    window.localStorage.removeItem(ACCESS_KEY);
    window.localStorage.removeItem(REFRESH_KEY);
  },
};

/** Fired when the refresh token is spent or rejected. The shell listens and
 *  sends the operator back to the sign-in screen. */
type SignOutListener = () => void;
const signOutListeners = new Set<SignOutListener>();

export function onForcedSignOut(listener: SignOutListener): () => void {
  signOutListeners.add(listener);
  return () => signOutListeners.delete(listener);
}

function forceSignOut(): void {
  tokenStore.clear();
  for (const listener of signOutListeners) listener();
}

/* --------------------------------------------------------- request engine */

async function parse<T>(response: Response): Promise<T | undefined> {
  const text = await response.text();
  if (!text) return undefined;
  let payload: SuccessEnvelope<T> | ErrorEnvelope;
  try {
    payload = JSON.parse(text) as SuccessEnvelope<T> | ErrorEnvelope;
  } catch {
    throw new ApiError(
      response.status,
      'BAD_RESPONSE',
      'The server returned a malformed response',
    );
  }
  if (!payload.success) {
    throw new ApiError(
      response.status,
      payload.error.code,
      payload.error.message,
      payload.error.details,
    );
  }
  return payload.data;
}

/**
 * Single-flight refresh: while a refresh is in flight every other 401 awaits
 * the same promise instead of spending the refresh token N times. Spending it
 * twice concurrently would revoke the session the operator is still using.
 */
let refreshInFlight: Promise<string> | null = null;

async function refreshAccessToken(): Promise<string> {
  if (refreshInFlight) return refreshInFlight;

  const refreshToken = tokenStore.refresh;
  if (!refreshToken) {
    forceSignOut();
    throw new ApiError(401, 'ADMIN_AUTH_REQUIRED', 'Your session has expired');
  }

  refreshInFlight = (async () => {
    const response = await fetch(`${ADMIN_BASE}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
    });
    const session = await parse<AdminSessionResponse>(response);
    if (!session) {
      throw new ApiError(
        response.status,
        'ADMIN_AUTH_REQUIRED',
        'Your session has expired',
      );
    }
    tokenStore.save(session);
    return session.accessToken;
  })();

  try {
    return await refreshInFlight;
  } catch (error) {
    // A failed refresh is terminal: the token is spent or revoked.
    forceSignOut();
    throw error;
  } finally {
    refreshInFlight = null;
  }
}

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  body?: unknown;
  query?: Record<string, string | number | boolean | undefined | null>;
  /** Set for the login call, which must not attempt a refresh on 401. */
  anonymous?: boolean;
}

function buildUrl(path: string, query: RequestOptions['query']): string {
  const url = new URL(`${ADMIN_BASE}${path}`);
  if (query) {
    for (const [key, value] of Object.entries(query)) {
      if (value === undefined || value === null || value === '') continue;
      url.searchParams.set(key, String(value));
    }
  }
  return url.toString();
}

async function request<T>(
  path: string,
  options: RequestOptions = {},
): Promise<T | undefined> {
  const { method = 'GET', body, query, anonymous = false } = options;
  const url = buildUrl(path, query);

  const send = async (token: string | null): Promise<Response> =>
    fetch(url, {
      method,
      headers: {
        ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });

  let response: Response;
  try {
    response = await send(anonymous ? null : tokenStore.access);
  } catch {
    throw new ApiError(
      0,
      'NETWORK_ERROR',
      'Could not reach the API. Check that the server is running and that this origin is in CORS_ALLOWED_ORIGINS.',
    );
  }

  // Replay once with a fresh token. Only 401 is retried — a 403 means the
  // role is wrong, and refreshing would not change that.
  if (response.status === 401 && !anonymous) {
    const token = await refreshAccessToken();
    response = await send(token);
  }

  return parse<T>(response);
}

/** For endpoints whose payload is required; throws if the body was empty. */
async function requireData<T>(
  path: string,
  options?: RequestOptions,
): Promise<T> {
  const data = await request<T>(path, options);
  if (data === undefined) {
    throw new ApiError(500, 'EMPTY_RESPONSE', 'The server returned no data');
  }
  return data;
}

/* ------------------------------------------------------------------- API */

export const adminApi = {
  /* auth */
  async login(email: string, password: string): Promise<AdminSessionResponse> {
    const session = await requireData<AdminSessionResponse>('/auth/login', {
      method: 'POST',
      body: { email, password },
      anonymous: true,
    });
    tokenStore.save(session);
    return session;
  },

  async logout(): Promise<void> {
    const refreshToken = tokenStore.refresh;
    if (refreshToken) {
      // A failed logout must not trap the operator in the panel.
      await request('/auth/logout', {
        method: 'POST',
        body: { refreshToken },
        anonymous: true,
      }).catch(() => undefined);
    }
    tokenStore.clear();
  },

  me: () => requireData<PublicAdminUser>('/auth/me'),

  changePassword: (currentPassword: string, newPassword: string) =>
    request<void>('/auth/change-password', {
      method: 'POST',
      body: { currentPassword, newPassword },
    }),

  /* metrics */
  overview: () =>
    requireData<{ source: MetricsSource; metrics: OverviewMetrics }>(
      '/metrics/overview',
    ),

  growth: (days: number) =>
    requireData<{ source: MetricsSource; days: number; series: GrowthMetrics }>(
      '/metrics/growth',
      { query: { days } },
    ),

  distributions: () =>
    requireData<{
      source: MetricsSource;
      distributions: DistributionMetrics;
    }>('/metrics/distributions'),

  activity: (limit = 12) =>
    requireData<{ source: MetricsSource; activity: ActivityEntry[] }>(
      '/metrics/activity',
      { query: { limit } },
    ),

  filters: () => requireData<FilterOptions>('/metrics/filters'),

  auditLog: (options: { action?: string; limit?: number } = {}) =>
    requireData<AuditLogEntry[]>('/audit-log', { query: { ...options } }),

  /* Firebase telemetry. Both may come back `configured: false` — that is a
     normal response describing setup state, not an error. */
  analyticsReport: (days: number) =>
    requireData<AnalyticsResponse>('/telemetry/analytics', { query: { days } }),

  crashReport: (days: number) =>
    requireData<CrashResponse>('/telemetry/crashes', { query: { days } }),

  /* farmers */
  users: (query: {
    search?: string;
    status?: UserStatusFilter;
    language?: string;
    state?: string;
    sort?: UserSort;
    page?: number;
    limit?: number;
  }) => requireData<UserListResult>('/users', { query }),

  user: (id: string) =>
    requireData<AdminUserDetail>(`/users/${encodeURIComponent(id)}`),

  setUserStatus: (id: string, isActive: boolean) =>
    request<void>(`/users/${encodeURIComponent(id)}/status`, {
      method: 'PATCH',
      body: { isActive },
    }),

  deleteUser: (id: string, reason: string) =>
    request<Record<string, number>>(`/users/${encodeURIComponent(id)}`, {
      method: 'DELETE',
      body: { reason },
    }),

  /* broadcasts */
  broadcasts: (query: { status?: BroadcastStatus; limit?: number } = {}) =>
    requireData<{ transport: PushTransport; broadcasts: Broadcast[] }>(
      '/broadcasts',
      { query },
    ),

  broadcastAnalytics: (days: number) =>
    requireData<BroadcastAnalytics>('/broadcasts/analytics', {
      query: { days },
    }),

  broadcast: (id: string) =>
    requireData<Broadcast>(`/broadcasts/${encodeURIComponent(id)}`),

  /** Counts registered devices, not farmers — a farmer with no device
   *  registered for push is in the audience but unreachable. */
  estimateAudience: (audience: BroadcastAudience) =>
    requireData<{ deviceCount: number; transport: PushTransport }>(
      '/broadcasts/estimate',
      { method: 'POST', body: audience },
    ),

  createBroadcast: (input: {
    title: string;
    body: string;
    category: BroadcastCategory;
    deepLink: string | null;
    audience: BroadcastAudience;
    scheduledAt: string | null;
    sendNow: boolean;
  }) =>
    requireData<Broadcast>('/broadcasts', { method: 'POST', body: input }),

  sendBroadcast: (id: string) =>
    request<Broadcast>(`/broadcasts/${encodeURIComponent(id)}/send`, {
      method: 'POST',
    }),

  cancelBroadcast: (id: string) =>
    request<Broadcast>(`/broadcasts/${encodeURIComponent(id)}/cancel`, {
      method: 'POST',
    }),

  deleteBroadcast: (id: string) =>
    request<void>(`/broadcasts/${encodeURIComponent(id)}`, {
      method: 'DELETE',
    }),

  /* market catalogue */
  products: () =>
    requireData<{ products: MarketProduct[] }>('/products'),

  createProduct: (input: MarketProductInput) =>
    requireData<MarketProduct>('/products', { method: 'POST', body: input }),

  updateProduct: (id: string, input: MarketProductInput) =>
    requireData<MarketProduct>(`/products/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: input,
    }),

  deleteProduct: (id: string) =>
    request<void>(`/products/${encodeURIComponent(id)}`, { method: 'DELETE' }),

  /* mandi prices */
  mandiPrices: (
    query: {
      state?: string;
      district?: string;
      commodity?: string;
      source?: MandiSource;
      search?: string;
      limit?: number;
    } = {},
  ) =>
    requireData<{ prices: MandiPriceRecord[]; count: number }>(
      '/mandi/prices',
      { query },
    ),

  mandiFilters: () => requireData<MandiFilterOptions>('/mandi/filters'),

  createMandiPrice: (input: MandiPriceInput) =>
    requireData<MandiPriceRecord>('/mandi/prices', {
      method: 'POST',
      body: input,
    }),

  updateMandiPrice: (id: string, input: MandiPriceInput) =>
    requireData<MandiPriceRecord>(`/mandi/prices/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: input,
    }),

  deleteMandiPrice: (id: string) =>
    request<void>(`/mandi/prices/${encodeURIComponent(id)}`, {
      method: 'DELETE',
    }),

  /* admin accounts (owner only) */
  admins: () => requireData<PublicAdminUser[]>('/admins'),

  createAdmin: (input: {
    email: string;
    name: string;
    password: string;
    role: AdminRole;
  }) => requireData<PublicAdminUser>('/admins', { method: 'POST', body: input }),

  updateAdmin: (
    id: string,
    changes: { name?: string; role?: AdminRole; isActive?: boolean },
  ) =>
    requireData<PublicAdminUser>(`/admins/${encodeURIComponent(id)}`, {
      method: 'PATCH',
      body: changes,
    }),

  resetAdminPassword: (id: string, newPassword: string) =>
    request<void>(`/admins/${encodeURIComponent(id)}/reset-password`, {
      method: 'POST',
      body: { newPassword },
    }),
};
