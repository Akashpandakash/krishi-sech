# Auth — `/api/auth`

Phone/OTP and Google sign-in, session refresh, and logout. Source:
[`server/src/auth/`](../../server/src/auth/).

Shared envelope, error codes, and conventions: [README](README.md).

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/send-otp` | — | Send a 6-digit code by SMS |
| POST | `/verify-otp` | — | Exchange the code for a session |
| POST | `/google` | — | Exchange a Google ID token for a session |
| POST | `/refresh` | — | Rotate the session |
| POST | `/logout` | — | Revoke a refresh token |
| GET | `/me` | ✓ | The signed-in user |

The whole router is rate-limited per IP by `AUTH_RATE_LIMIT_MAX` over
`RATE_LIMIT_WINDOW_MS`, on top of the per-phone OTP limits below.

## Token model

| Token | Lifetime | Notes |
| --- | --- | --- |
| `accessToken` | 15 minutes | Sent as `Authorization: Bearer <token>` |
| `refreshToken` | 30 days | **Rotates on every use** — the old one is revoked |

Because refresh rotates, persist the new pair atomically. Writing the access
token but losing the refresh token bricks the session at the next refresh.

## POST `/send-otp`

Request:

```json
{ "phone": "+919876543210" }
```

`phone` must be E.164 — `^\+[1-9]\d{7,14}$`. A bare `9876543210` is a
`VALIDATION_ERROR`; the app prepends the country code before sending.

Response `200`:

```json
{
  "success": true,
  "message": "OTP sent successfully",
  "data": { "debugOtp": "418302" }
}
```

`debugOtp` is present only where `DEBUG_OTP_ENABLED` is set — development and
staging. Production returns `"data": {}`. Never render it outside a debug build.

The code is valid for **5 minutes**. Sending again issues a fresh code and
invalidates nothing — verification checks the latest code only. There is no
separate resend endpoint; a resend is just another `/send-otp`, and it counts
against the per-phone limit.

### Rate limiting

`OTP_MAX_REQUESTS_PER_WINDOW` sends (default 3) per
`OTP_REQUEST_WINDOW_SECONDS` (default 600) per phone number:

```json
{
  "success": false,
  "error": {
    "code": "OTP_RATE_LIMITED",
    "message": "Too many OTP requests. Please try again later"
  },
  "requestId": "…"
}
```

The response carries no retry hint, so the client should run its own resend
cooldown rather than letting the farmer discover the limit by hitting it.

## POST `/verify-otp`

Request:

```json
{ "phone": "+919876543210", "otp": "418302" }
```

`otp` is a 6-digit **string** — `418302`, not `418302` as a number. Leading
zeros are significant and JSON numbers would eat them.

Response `200`:

```json
{
  "success": true,
  "message": "OTP verified successfully",
  "data": {
    "user": {
      "id": "0f2b9c4e-1d76-4a30-9c11-8e5d3a7f6b02",
      "phone": "+919876543210",
      "name": null,
      "preferredLanguage": "bn",
      "isActive": true,
      "createdAt": "2026-08-17T09:14:22.481Z",
      "updatedAt": "2026-08-17T09:14:22.481Z"
    },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9…",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9…",
    "expiresIn": 900
  }
}
```

**The account is created on first successful verify.** There is no separate
signup call, which is why `name` is `null` for a new farmer — route them to
profile setup when it is.

`expiresIn` is the access token's lifetime in seconds, not an absolute time.

### Errors

| Status | Code | Meaning |
| --- | --- | --- |
| 400 | `OTP_EXPIRED` | No code on file, or it is past its 5 minutes |
| 400 | `OTP_INVALID` | Wrong code. The attempt counter increments |
| 429 | `OTP_ATTEMPTS_EXCEEDED` | 5 failed attempts against one code — a new code is required |
| 403 | `USER_INACTIVE` | An admin blocked the account |

`OTP_EXPIRED` and `OTP_INVALID` both carry the message `"OTP is invalid or
expired"` on purpose — the pair does not reveal whether a code existed. Show one
message for both and offer resend.

## POST `/google`

Request:

```json
{ "idToken": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjE2…" }
```

Response `200`: identical to verify-otp, except `phone` is `null` and `email`
carries the Google address.

The ID token is the only evidence trusted — the client never asserts its own
identity, and no email or user ID from the client is read. The token's audience
must match the backend's configured client ID, which is why Android must pass
`googleServerClientId` as `serverClientId` when requesting the token. Get that
wrong and the backend rejects a token the app considers perfectly valid.

| Status | Code | Meaning |
| --- | --- | --- |
| 503 | `GOOGLE_LOGIN_UNAVAILABLE` | This deployment has no Google client configured. Hide the button rather than offering one that cannot work |
| 403 | `ACCOUNT_DISABLED` | The linked account was blocked |

## POST `/refresh`

Request:

```json
{ "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9…" }
```

Response `200`: a full session payload, same shape as verify-otp, with **both
tokens replaced**. The submitted refresh token is revoked in the same operation.

| Status | Code | Meaning |
| --- | --- | --- |
| 401 | `REFRESH_TOKEN_INVALID` | Revoked, expired, unknown, or belongs to another user. Terminal — sign out |

Two clients refreshing concurrently with the same token means one wins and the
other gets `REFRESH_TOKEN_INVALID`. Serialize refreshes behind a single-flight
lock so parallel 401s do not each trigger their own refresh.

## POST `/logout`

Request:

```json
{ "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9…" }
```

Response `200`:

```json
{ "success": true, "message": "Logged out successfully" }
```

No `data`. Revokes the refresh token server-side; the access token stays valid
until it expires, so clear it locally too. Unregister the FCM token *before*
logging out — see [Devices](devices.md) — or the handset keeps receiving
broadcasts for the old account.

## GET `/me`

Requires `Authorization`. Response `200`:

```json
{
  "success": true,
  "message": "Authenticated user retrieved",
  "data": {
    "id": "0f2b9c4e-1d76-4a30-9c11-8e5d3a7f6b02",
    "phone": "+919876543210",
    "name": "Ranjan Das",
    "preferredLanguage": "bn",
    "isActive": true,
    "createdAt": "2026-08-17T09:14:22.481Z",
    "updatedAt": "2026-08-17T10:02:07.119Z"
  }
}
```

Use it to validate a restored session at startup. It returns `404
USER_NOT_FOUND` for a deleted or deactivated account, which is the signal to
clear local storage.

## Handling 401 in the client

On `401 TOKEN_INVALID`, refresh once and replay the original request. If the
refresh also fails, sign out.

There is no separate "expired" code to branch on, so **cap the retry at one
attempt** — a genuinely malformed token returns `TOKEN_INVALID` forever and an
uncapped retry loops. On `REFRESH_TOKEN_INVALID` or `AUTH_REQUIRED`, clear
storage and return to login without retrying.

## Demo login

Sending `x-krishi-development-client: true` unlocks the demo account
`+919999999999` with the fixed code `123456`, when the deployment has
`DEMO_LOGIN_ENABLED`. `send-otp` for that number short-circuits the SMS provider
and returns the code directly. The header is ignored outside development, and
the Flutter guard in `AppEnvironment.validate()` refuses to build a staging or
production app with demo login enabled.
