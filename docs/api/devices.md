# Devices — `/api/devices`

FCM push token registration. Source:
[`server/src/devices/`](../../server/src/devices/).

Shared envelope, error codes, and conventions: [README](README.md).
**All routes require `Authorization`.**

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/` | Register or refresh a token |
| GET | `/` | List this account's devices |
| DELETE | `/` | Unregister a token |

A registered token is what makes an account reachable by a
[broadcast](notifications.md). Without one the messages still arrive in the
inbox; the handset just is not woken for them.

## POST `/`

```http
POST /api/devices
Authorization: Bearer <accessToken>
Content-Type: application/json
```

```json
{
  "token": "fMEP0vJhTQmZ8x1cW3nKdR:APA91bH7yQ2v…",
  "platform": "android"
}
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `token` | string | ✓ | 32–4096 chars, trimmed |
| `platform` | enum | ✓ | `android`, `ios`, `web` |

The length bound is deliberately loose — FCM publishes no fixed token format, so
the check only rejects obvious junk and oversized bodies.

Response `200`:

```json
{
  "success": true,
  "message": "Device registered successfully",
  "data": {
    "id": "d-8c41f0a7-6d54-4b29-9e07-2fa61b8d5c93",
    "platform": "android",
    "updatedAt": "2026-08-17T12:18:44.310Z"
  }
}
```

**The token itself is never echoed back.** It is a credential for waking the
device, and the response deliberately returns only the record ID, platform, and
timestamp. Keep your own copy if you need to compare against the current FCM
token.

Registration is an upsert keyed on the **token**, not on the account:
re-posting the same token updates the existing record instead of creating a
duplicate, so it is safe to call on every launch. Because the key is the token,
registering after a different farmer signs in on the same handset *transfers*
that token to the new account rather than adding a second registration — which
is the correct behaviour on a shared family phone.

## GET `/`

Response `200`:

```json
{
  "success": true,
  "message": "Devices retrieved successfully",
  "data": [
    {
      "id": "d-8c41f0a7-6d54-4b29-9e07-2fa61b8d5c93",
      "platform": "android",
      "createdAt": "2026-06-15T05:33:02.771Z",
      "updatedAt": "2026-08-17T12:18:44.310Z"
    }
  ]
}
```

A bare array in `data`, again without tokens. There is no device name or model —
`platform` and the timestamps are all that distinguishes two entries, which
makes this list thin for a "manage your devices" screen. It is mostly useful for
confirming that registration worked.

## DELETE `/`

The token goes in the **body**, not the path:

```http
DELETE /api/devices
Authorization: Bearer <accessToken>
Content-Type: application/json
```

```json
{ "token": "fMEP0vJhTQmZ8x1cW3nKdR:APA91bH7yQ2v…" }
```

Response `200`:

```json
{ "success": true, "message": "Device unregistered successfully" }
```

No `data`. Unregistering an unknown token succeeds rather than 404ing, so it is
safe to call defensively.

Note that unregister is **not scoped to the calling account** — it removes the
token wherever it is registered. That is what makes logout work correctly on a
shared handset, but it also means the call needs a valid session while
deliberately affecting a record that may belong to a different account.

## Lifecycle

Four moments matter, and missing any of them produces a bug that only shows up
in the field:

| When | Do |
| --- | --- |
| After login | `POST /` with the current FCM token |
| On FCM token rotation | `POST /` with the new token |
| **Before logout** | `DELETE /` with the current token |
| On permission revoked | `DELETE /` |

**Unregister before logout, not after.** Both calls require a valid session, and
once the refresh token is revoked the delete will fail with `401`. Get the order
wrong and the handset keeps receiving broadcasts targeted at the account that
just signed out — on a shared family phone, that is another farmer's advisory.

FCM rotates tokens on reinstall, restore-from-backup, and occasionally on its
own. Register from the token-refresh callback, not only at startup, or push
silently stops working for that handset.

Stale tokens are cleaned up server-side when a send reports them as
unregistered, so a token left behind eventually disappears — but "eventually"
means "after the next broadcast to that audience", which may be weeks.

## Errors

| Status | Code | Meaning |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Token under 32 or over 4096 chars, or an unknown `platform` |
| 401 | `AUTH_REQUIRED` / `TOKEN_INVALID` | No valid session — see the logout ordering above |

Deleting the account through [Account](account.md) removes every device
registration for it, so no unregister call is needed in that flow.
