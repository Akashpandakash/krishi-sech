# Admin — `/api/admin`

The admin panel API: auth, metrics, farmer management, broadcasts, and
catalogue management. Source:
[`server/src/admin/`](../../server/src/admin/), consumed by the Next.js app in
[`web/`](../../web/).

Shared envelope, error codes, and conventions: [README](README.md).

**This is a separate auth system.** Farmer JWTs are rejected here, and admin
tokens are rejected on the farmer routes. Different secrets, different token
type claim, different lifetimes.

## Roles

| Role | Can |
| --- | --- |
| `analyst` | Read everything — metrics, users, broadcasts, audit log, telemetry |
| `admin` | Also act on farmers, broadcasts, products, and mandi rows |
| `owner` | Also manage admin accounts |

Every **write** is recorded in the audit log with the acting admin, the target,
a human-readable summary, and the client IP. Reads are not logged.

## Auth — `/auth`

| Method | Path | Role |
| --- | --- | --- |
| POST | `/login` | — |
| POST | `/refresh` | — |
| POST | `/logout` | — |
| GET | `/me` | any |
| POST | `/change-password` | any |

### POST `/auth/login`

```json
{ "email": "ops@krishisech.com", "password": "…" }
```

Response `200`:

```json
{
  "success": true,
  "message": "Signed in successfully",
  "data": {
    "admin": {
      "id": "a-1f8c…",
      "email": "ops@krishisech.com",
      "name": "Operations",
      "role": "admin",
      "isActive": true,
      "lastLoginAt": "2026-08-17T08:02:11.400Z",
      "createdAt": "2026-01-04T10:00:00.000Z",
      "updatedAt": "2026-08-17T08:02:11.400Z"
    },
    "accessToken": "…",
    "refreshToken": "…",
    "expiresIn": 1800
  }
}
```

`passwordHash` is stripped from every admin object the API returns.

Admin access tokens default to **30 minutes** (`ADMIN_ACCESS_TOKEN_TTL_SECONDS`),
longer than the farmer app's 15. Send as `Authorization: Bearer <accessToken>`.

Repeated failed logins lock the account temporarily:

```json
{
  "success": false,
  "error": {
    "code": "ADMIN_LOCKED_OUT",
    "message": "Too many failed attempts. Try again later"
  },
  "requestId": "…"
}
```

The lockout is tracked in process memory, so it resets on a server restart and
is not shared across instances.

### POST `/auth/refresh` and `/auth/logout`

Both take `{ "refreshToken": "…" }`. Refresh returns a fresh session payload;
logout returns no `data`.

### POST `/auth/change-password`

```json
{ "currentPassword": "…", "newPassword": "…" }
```

New passwords must be **at least 12 characters** and pass a strength check;
failures come back as `400 WEAK_PASSWORD` with the specific reason in
`error.message`. Changing a password revokes existing sessions.

### Auth errors

| Status | Code | Meaning |
| --- | --- | --- |
| 401 | `ADMIN_AUTH_REQUIRED` | Missing or malformed bearer token |
| 401 | `ADMIN_CREDENTIALS_INVALID` | Wrong email or password — deliberately does not say which |
| 401 | `ADMIN_SESSION_INVALID` | Token expired, revoked, or the admin was deactivated |
| 403 | `ADMIN_FORBIDDEN` | Authenticated, but the role does not allow this action |
| 429 | `ADMIN_LOCKED_OUT` | Too many failed attempts |
| 400 | `WEAK_PASSWORD` | Under 12 chars or failed the strength check |
| 404 | `ADMIN_NOT_FOUND` | No such admin |
| 409 | `ADMIN_EXISTS` | That email is already registered |

`ADMIN_FORBIDDEN` versus `ADMIN_SESSION_INVALID` matters in the UI: the first
means "sign in as someone else", the second means "sign in again".

## Metrics — `/metrics`, `/audit-log`

All readable by `analyst` and up.

| Method | Path | Query | Returns |
| --- | --- | --- | --- |
| GET | `/metrics/overview` | | `{ source, metrics }` |
| GET | `/metrics/growth` | `days` 7–365, default 30 | `{ source, days, series }` |
| GET | `/metrics/distributions` | | `{ source, distributions }` |
| GET | `/metrics/activity` | `limit` 1–50, default 12 | `{ source, activity }` |
| GET | `/metrics/filters` | | Filter option lists |
| GET | `/audit-log` | `action`, `limit` 1–200 default 50 | Audit entries |

`source` is always `"database"`. The generated-sample-data implementation was
removed deliberately — the panel only ever shows real rows, so an empty
dashboard means an empty database, never a broken fallback.

`overview.metrics`:

```json
{
  "totalUsers": 1842, "activeUsers": 1790, "blockedUsers": 52,
  "newUsersToday": 12, "newUsers7d": 96, "newUsers30d": 411,
  "returningUsers7d": 623, "returningUsers30d": 1104,
  "farmProfiles": 1502, "totalLandAcres": 7431.5,
  "totalCrops": 3980, "crops30d": 302,
  "totalTasks": 12045, "pendingTasks": 3120,
  "completedTasks": 8402, "overdueTasks": 523,
  "fertilizerRecommendations": 2211, "irrigationRecommendations": 3390
}
```

`growth.series` holds four `{ date, value }[]` series: `signups`, `logins`,
`cropsCreated`, `tasksCompleted`. `distributions` holds nine
`{ label, value }[]` slices: `languages`, `states`, `cropNames`, `soilTypes`,
`irrigationMethods`, `growthStages`, `farmerTypes`, `taskTypes`, `cropHealth`.

`activity` is `{ type: "signup" | "crop" | "task", label, detail, at }[]`.

Audit entries are `{ id, adminId, adminEmail, action, targetType, targetId,
summary, ipAddress, createdAt }`. Filter by `action` with values like
`admin.login`, `user.blocked`, `broadcast.sent`, `product.created`.

## Users — `/users`

| Method | Path | Role | Purpose |
| --- | --- | --- | --- |
| GET | `/users` | any | Paged list |
| GET | `/users/:id` | any | Full detail |
| PATCH | `/users/:id/status` | admin+ | Block or unblock |
| DELETE | `/users/:id` | admin+ | Delete the account |

List query: `search`, `status` (`all`/`active`/`blocked`, default `all`),
`language`, `state`, `sort` (`recent`/`oldest`/`crops`/`lastSeen`, default
`recent`), `page` (default 1), `limit` (1–100, default 20).

Response: `{ source, users, total, page, limit }`. Each summary carries `id`,
`phone`, `email`, `name`, `preferredLanguage`, `state`, `district`, `village`,
`isActive`, `createdAt`, `lastSeenAt`, `cropCount`, `taskCount`. `phone` is
`null` for Google accounts.

`GET /users/:id` adds `farm`, `crops[]`, `tasks[]`, `sessions[]`, and device
registrations — enough to answer a support call.

**PATCH `/users/:id/status`** takes `{ "isActive": false }`. Blocking is
reversible and takes effect on the farmer's next request: their access token
keeps working until it expires (up to 15 minutes), then refresh fails. Do not
expect an instant cut-off.

**DELETE `/users/:id`** requires `{ "reason": "…" }`, 3–300 characters. Unlike
the farmer's own deletion, this reason **is** recorded in the audit log. The
purge is the same one described in [Account](account.md) — immediate,
irreversible, no grace period.

## Broadcasts — `/broadcasts`

| Method | Path | Role |
| --- | --- | --- |
| GET | `/broadcasts` | any |
| GET | `/broadcasts/:id` | any |
| GET | `/broadcasts/analytics` | any |
| POST | `/broadcasts/estimate` | any |
| POST | `/broadcasts` | admin+ |
| POST | `/broadcasts/:id/send` | admin+ |
| POST | `/broadcasts/:id/cancel` | admin+ |
| DELETE | `/broadcasts/:id` | admin+ |

### Create

```json
{
  "title": "Heavy rain expected in Nadia",
  "body": "Delay irrigation for the next two days and check field drainage.",
  "category": "weather",
  "deepLink": "krishisech://weather",
  "audience": {
    "language": "bn",
    "state": "West Bengal",
    "farmerType": null,
    "onlyActive": true
  },
  "scheduledAt": null,
  "sendNow": false
}
```

`title` 3–80 chars, `body` 3–500. `category` is `general` (default), `weather`,
`advisory`, `market`, or `maintenance`. Every audience field is nullable —
`null` means "no filter on this dimension", so all-null with `onlyActive: true`
reaches every active farmer.

`sendNow: true` sends immediately and returns `201` with status `sent`;
otherwise it saves as `draft` or `scheduled`.

**Estimate before sending.** `POST /broadcasts/estimate` takes the audience
object alone and returns `{ deviceCount, transport }` — how many *devices*, not
accounts, the filter reaches. An account with no registered device counts for
zero. Run it before every send; a typo in `farmerType` (which is free text on
the farm profile) silently narrows the audience to nothing.

### Broadcast object

`{ id, title, body, category, deepLink, audience, status, createdByAdminId,
createdByAdminEmail, scheduledAt, sentAt, audienceCount, deliveredCount,
failedCount, failureReason, createdAt, updatedAt }`.

Status is `draft`, `scheduled`, `sending`, `sent`, `failed`, or `cancelled`.

A push failure never hides the message — it stays readable in the farmer's
[inbox](notifications.md), so the broadcast is still `sent` and
`deliveredCount`/`failedCount` carry the detail. `deliveredCount <
audienceCount` is normal, not an error.

`GET /broadcasts` returns `{ transport, broadcasts }`, where `transport`
reports whether push is actually configured. With push unconfigured, broadcasts
still land in inboxes and `deliveredCount` stays zero.

`/broadcasts/analytics?days=` returns delivery totals, a per-day series, device
counts by platform, and a `deliveryRate` percentage.

## Products — `/products`

| Method | Path | Role |
| --- | --- | --- |
| GET | `/products` | any |
| POST | `/products` | admin+ |
| PUT | `/products/:id` | admin+ |
| DELETE | `/products/:id` | admin+ |

Mounted only where the market service is configured.

Unlike the [farmer-facing market](market.md), the admin view returns **raw
localized maps**, not resolved strings, and includes inactive products:

```json
{
  "name": { "en": "Swarna paddy seed", "bn": "স্বর্ণ ধানের বীজ" },
  "description": { "en": "High-yield aman paddy seed, 10 kg bag.", "bn": "…" },
  "category": "seeds",
  "price": 850,
  "unit": "bag",
  "stockQuantity": 42,
  "vendor": "Nadia Agro Supplies",
  "isActive": true
}
```

`en` is **required** on both `name` and `description` — it is the fallback every
other locale resolves to. Other keys must be app locales; anything else fails
with "contains a language the app does not support". `price` is whole rupees,
max 10,000,000.

Setting `isActive: false` delists a product: it vanishes from the farmer
catalogue but stays for order history.

## Mandi prices — `/mandi`

| Method | Path | Role |
| --- | --- | --- |
| GET | `/mandi/filters` | any |
| GET | `/mandi/prices` | any |
| POST | `/mandi/prices` | admin+ |
| PUT | `/mandi/prices/:id` | admin+ |
| DELETE | `/mandi/prices/:id` | admin+ |

Mounted only where the mandi service is configured. List query: `state`,
`district`, `commodity`, `source`, `search`, `limit` (1–500, default 100).
Returns `{ prices, count }`.

Create and update bodies require `state`, `district`, `market`, `commodity`,
`arrivalDate`, `minPrice`, `maxPrice`, `modalPrice`, with `variety` and `grade`
nullable. Prices are integers in rupees per quintal, 1 to 10,000,000, and must
satisfy `minPrice ≤ modalPrice ≤ maxPrice` — violations name the offending field.

Admin-entered rows are stored with `source: "manual"` and **survive a feed
refresh**: the nightly AGMARKNET import skips any row an operator has taken
over, so a correction is not silently undone. This is also what backs the
farmer-facing `live: false` case described in [Mandi](mandi.md).

## Telemetry — `/telemetry`

`GET /telemetry/analytics?days=` and `GET /telemetry/crashes?days=` (1–90,
default 28), readable by `analyst` and up. Both proxy Google integrations —
GA4 and Crashlytics via BigQuery.

When an integration is not configured, or the upstream call fails, the response
says so rather than returning zeros:

```json
{
  "configured": false,
  "integration": "crashlytics",
  "reason": "Not configured: BIGQUERY_PROJECT_ID, CRASHLYTICS_BIGQUERY_TABLE are not set.",
  "missing": ["BIGQUERY_PROJECT_ID", "CRASHLYTICS_BIGQUERY_TABLE"]
}
```

**Check `configured` before rendering.** The guiding rule is that an operator
must be able to tell "nothing crashed" apart from "we cannot see crashes" — a
dashboard that renders `configured: false` as a zero destroys exactly that
distinction.

## Admins — `/admins`

Owner only.

| Method | Path | Body |
| --- | --- | --- |
| GET | `/admins` | |
| POST | `/admins` | `{ email, name, password, role }` |
| PATCH | `/admins/:id` | `{ name?, role?, isActive? }`, at least one |
| POST | `/admins/:id/reset-password` | `{ newPassword }` |

Passwords are 12–200 characters and pass the same strength check as
`change-password`. `name` is 2–80 characters, `role` is `owner`, `admin`, or
`analyst`.
