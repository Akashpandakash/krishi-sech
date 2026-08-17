# API documentation

Client-side reference for the Krishi Sech backend, one document per backend
module. Read this page first — it covers the envelope, errors, and conventions
that every module inherits and none of them repeat.

Written against `server/src`. Where a module doc disagrees with the code, the
code wins; routes are assembled in [`server/src/app.ts`](../../server/src/app.ts).

## Modules

### Farmer app

| Module | Base path | Covers |
| --- | --- | --- |
| [Auth](auth.md) | `/api/auth` | OTP and Google sign-in, refresh, logout |
| [Crops](crops.md) | `/api/crops` | The farmer's crop records |
| [Calendar](calendar.md) | `/api/calendar` | Farming tasks and reminders |
| [Profile](profile.md) | `/api/profile` | User profile and farm profile |
| [Weather](weather.md) | `/api/weather` | Current conditions and today's forecast |
| [Irrigation](irrigation.md) | `/api/irrigation` | Watering recommendation |
| [Fertilizer](fertilizer.md) | `/api/fertilizer` | Fertilizer recommendation |
| [AI](ai.md) | `/api/ai` | Farming context, chat, disease scan |
| [Mandi](mandi.md) | `/api/mandi` | Market price quotes |
| [Market](market.md) | `/api/market` | Product catalogue |
| [Notifications](notifications.md) | `/api/notifications` | In-app inbox |
| [Devices](devices.md) | `/api/devices` | FCM push registration |
| [Account](account.md) | `/api/account` | Account deletion |

### Admin panel

| Module | Base path | Covers |
| --- | --- | --- |
| [Admin](admin.md) | `/api/admin` | Admin auth, metrics, users, broadcasts, catalogue |

### Client

| Document | Covers |
| --- | --- |
| [Flutter client](flutter-client.md) | How the app is layered, and how to add an endpoint |

## Base URL

Every route is mounted under `/api`. The Flutter app's base URL is a
compiled-in constant — `apiBaseUrl` in
[`lib/core/config/app_environment.dart`](../../lib/core/config/app_environment.dart).
There is no dart-define or config file; edit the constant and rebuild.

| Target | Base URL |
| --- | --- |
| Android emulator against a local backend | `http://10.0.2.2:3000` |
| Physical device on the same Wi-Fi | `http://<host-LAN-IP>:3000` |
| Staging | `https://stage-api.krishisech.com` |

The Next.js admin panel reads `NEXT_PUBLIC_API_BASE_URL` from the environment,
since it deploys separately.

## Health probes

Unauthenticated, for infrastructure rather than app code.

```http
GET /api/health
```

```json
{ "success": true, "message": "Krishi Sech Backend Running" }
```

```http
GET /api/ready
```

```json
{
  "success": true,
  "status": "ready",
  "checks": { "backend": "ok", "environment": "ok", "database": "ok" }
}
```

`/api/ready` adds a 3-second MongoDB ping and answers `503` with
`"status": "not_ready"` and `"database": "unavailable"` when the database is
unreachable. Point platform health checks at `/api/ready` so an instance is not
admitted before its database is.

## Response envelope

Every response — success or failure — is JSON with a `success` boolean. Nothing
is ever returned as a bare array or scalar at the top level.

```json
{
  "success": true,
  "message": "Crops retrieved successfully",
  "data": []
}
```

`data` is omitted entirely when an endpoint has nothing to return (deletes,
logout, mark-as-read). `message` is English and server-authored — it is for logs
and developers, **not** for display. The app renders its own localized strings
from the ARB catalogue.

Errors:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [
      { "path": "phone", "message": "Phone number must use E.164 format" }
    ]
  },
  "requestId": "3f9c1a7e-5d2b-4c8a-9e13-7b40f2a6c081"
}
```

`details` appears only on `VALIDATION_ERROR`. `requestId` is on every error and
matches the ID in the server logs — surface it in bug reports.

Branch on `error.code`, never on `error.message`. Messages are rewritten freely,
and in production any 5xx message is replaced with `"Service temporarily
unavailable"`, so the client cannot parse it.

## Shared error codes

Module docs list the codes specific to them. These can come back from anywhere:

| Status | Code | When |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Body or query failed the schema; `details` lists field paths |
| 401 | `AUTH_REQUIRED` | Missing or malformed `Authorization` header |
| 401 | `TOKEN_INVALID` | Access token rejected. Covers expired *and* malformed — the server does not distinguish them |
| 403 | `USER_INACTIVE` | Account deactivated by an admin |
| 404 | `NOT_FOUND` | No such route |
| 429 | `RATE_LIMITED` | Per-IP limiter on `/api/auth` or `/api/ai` |
| 500 | `INTERNAL_ERROR` | Unhandled — retry once, then surface a generic failure |

A resource owned by another user returns `404`, not `403`. Ownership is scoped
into every query, so the server does not distinguish "missing" from "not yours".

## Authentication

Bearer JWTs on every route except the health probes, weather, and the
unauthenticated halves of auth and account deletion.

```http
Authorization: Bearer <accessToken>
```

Access tokens live 15 minutes, refresh tokens 30 days, and **refresh tokens
rotate on use**. See [Auth](auth.md) for the full handshake and the retry rule.

## Conventions

**Dates.** Every date crosses the wire as an ISO-8601 UTC string
(`2026-08-17T09:00:00.000Z`) and must be parsed as UTC. Sending a local-time
string without an offset will be misread.

**Optional mounts.** Routers are mounted only when their service was composed.
`/api/mandi`, `/api/market`, `/api/ai/chat`, and `/api/ai/disease-scan` are
absent on deployments without the corresponding provider configured. A missing
router answers `404 NOT_FOUND`, which reads identically to a typo'd path — treat
`404` on a whole feature as "feature unavailable", not as a bug.

**Body size.** JSON bodies are capped at 32 KB. Crop images are capped at 2 MB
and must be JPEG, PNG, or WebP.

**Security headers.** Responses carry `Cache-Control: no-store`, `X-Frame-Options:
DENY`, `X-Content-Type-Options: nosniff`, and a restrictive CSP. Nothing from
this API is cacheable by an HTTP layer — cache in the client if you need to.

**CORS.** Browser clients must have their origin in `CORS_ALLOWED_ORIGINS`. The
Flutter app is unaffected.

## Shared enums

Mirror these exactly; anything else is a `VALIDATION_ERROR`.

| Enum | Values | Used by |
| --- | --- | --- |
| `growthStage` | `sowing`, `germination`, `seedling`, `vegetative`, `flowering`, `fruiting`, `maturity`, `harvested` | [Crops](crops.md) |
| `landUnit` | `acre`, `hectare`, `bigha`, `katha` | [Crops](crops.md) |
| `soilType` | `alluvial`, `black`, `red`, `laterite`, `sandy`, `clay`, `loamy`, `other` | [Crops](crops.md) |
| `irrigationMethod` | `drip`, `sprinkler`, `flood`, `rainFed`, `manual` | [Crops](crops.md) |
| `healthStatus` | `healthy`, `moderate`, `needsAttention` | [Crops](crops.md) |
| `taskType` | `irrigation`, `fertilizer`, `pestInspection`, `harvest` | [Calendar](calendar.md) |
| task `status` | `pending`, `completed` | [Calendar](calendar.md) |
| `landType` | `upland`, `lowland`, `irrigated`, `rainfed` | [Irrigation](irrigation.md) |
| market `category` | `seeds`, `fertilizers`, `tools` | [Market](market.md) |
| market `unit` | `bag`, `pack`, `piece`, `kg`, `litre` | [Market](market.md) |
| mandi `source` | `agmarknet`, `manual` | [Mandi](mandi.md) |
| AI `language` | `bn`, `en`, `hi` | [AI](ai.md), [Irrigation](irrigation.md), [Fertilizer](fertilizer.md), [Weather](weather.md) |
| App locale | `as`, `bn`, `brx`, `doi`, `gu`, `hi`, `kn`, `ks`, `kok`, `mai`, `ml`, `mni`, `mr`, `ne`, `or`, `pa`, `sa`, `sat`, `sd`, `ta`, `te`, `ur`, `en` | [Profile](profile.md), [Market](market.md) |
| broadcast `category` | `general`, `weather`, `advisory`, `market`, `maintenance` | [Notifications](notifications.md), [Admin](admin.md) |
| broadcast `status` | `draft`, `scheduled`, `sending`, `sent`, `failed`, `cancelled` | [Admin](admin.md) |
| admin `role` | `owner`, `admin`, `analyst` | [Admin](admin.md) |

Two casing traps worth knowing:

- `rainFed` is camelCase as a crop `irrigationMethod`, but `rainfed` is
  lowercase as an irrigation `landType`. Different enums.
- The recommendation and AI endpoints accept only `bn`/`en`/`hi`, while profile
  and market accept all 23 app locales. Passing `ta` to the chat endpoint is a
  validation error.
