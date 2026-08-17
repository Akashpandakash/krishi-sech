# Account — `/api/account`

Account deletion, from the app and from the web. Source:
[`server/src/account/`](../../server/src/account/).

Shared envelope, error codes, and conventions: [README](README.md).

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| POST | `/deletion/send-otp` | **none** | Send a code to the account's number |
| POST | `/deletion/confirm` | **none** | Verify the code and erase the account |
| DELETE | `/` | ✓ | Erase the signed-in account |

Two paths to the same outcome. Google Play's data-deletion policy requires a
route a farmer can complete **without installing the app**, which is why the web
flow proves ownership by OTP rather than by session — it stands entirely apart
from sign-in.

Deletion is **immediate and irreversible**. There is no soft delete, no grace
period, and no undo. Confirm destructively in the UI: state what will be lost,
require an explicit action, and do not make it reachable by a stray tap.

## Web flow

### POST `/deletion/send-otp`

```json
{ "phone": "+919876543210" }
```

E.164, same rule as [Auth](auth.md). Response `200`:

```json
{
  "success": true,
  "message": "Verification code sent to your phone",
  "data": {}
}
```

This reuses the sign-in OTP machinery — same 5-minute validity, same 5-attempt
limit, same per-phone rate limit and `OTP_RATE_LIMITED` response. It does **not**
pass the development-client flag, so the demo account shortcut is unavailable
here even in development.

A `debugOtp` appears in `data` where `DEBUG_OTP_ENABLED` is set, exactly as in
sign-in.

Note that this answers `200` whether or not an account exists for the number —
it does not confirm registration. The account check happens at confirm time.

### POST `/deletion/confirm`

```json
{
  "phone": "+919876543210",
  "otp": "418302",
  "reason": "I no longer farm this land."
}
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `phone` | string | ✓ | E.164 |
| `otp` | string | ✓ | 6 digits, as a string |
| `reason` | string | | Max 500 chars, trimmed |

Response `200`:

```json
{
  "success": true,
  "message": "Your account and all its data have been deleted",
  "data": {
    "crops": 3,
    "calendarTasks": 17,
    "farmProfiles": 1,
    "fertilizerRecommendations": 8,
    "irrigationRecommendations": 12,
    "devices": 2,
    "notificationReceipts": 24,
    "sessions": 1
  }
}
```

`data` is the deletion summary — a count per collection erased. Show it as
confirmation; it is the only receipt the farmer gets.

Verifying the code here **does not create an account or mint a session**. It
proves ownership of the number and nothing else, which is what makes it safe to
expose unauthenticated. A number with no Krishi Sech account gets `404
ACCOUNT_NOT_FOUND` rather than silently creating one — the opposite of
[`/api/auth/verify-otp`](auth.md), which creates an account on first verify.

## In-app flow

### DELETE `/`

```http
DELETE /api/account
Authorization: Bearer <accessToken>
Content-Type: application/json
```

```json
{ "reason": "Switching to another app." }
```

The body is optional entirely — `{}` or no body at all is valid. Only `reason`
is read, max 500 chars.

Response `200`: the same message and deletion summary as the web flow.

No OTP is required; the access token already proves ownership.

## After deletion

Every token for the account stops working immediately. So:

- **Do not call logout afterwards.** It will fail with
  `REFRESH_TOKEN_INVALID`. Clear local storage directly.
- **Do not unregister the device first.** Device registrations are erased as
  part of the purge — the `devices` count in the summary confirms it.
- Clear cached crops, tasks, and profile data. A stale local cache after a
  successful deletion is the one way a "deleted" account still appears to exist.

The order that works: call delete → show the summary → wipe local storage →
return to the login screen.

## The `reason` is not stored

`reason` is free text from the account holder and is deliberately **not
persisted anywhere that survives the deletion**. Only a boolean — whether a
reason was given — reaches the logs.

Do not promise the farmer that someone will read it, and do not build a support
workflow on it. If you need exit feedback, collect it separately before calling
this endpoint.

## Errors

| Status | Code | Meaning |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Bad phone format, non-6-digit OTP, over-long reason |
| 400 | `OTP_EXPIRED` / `OTP_INVALID` | Wrong or expired code |
| 429 | `OTP_RATE_LIMITED` | Too many sends for that number |
| 429 | `OTP_ATTEMPTS_EXCEEDED` | 5 failed attempts against one code |
| 404 | `ACCOUNT_NOT_FOUND` | The number verified, but no account uses it |
| 401 | `AUTH_REQUIRED` / `TOKEN_INVALID` | In-app flow without a valid session |
| 500 | `ACCOUNT_DELETION_FAILED` | The purge failed partway |

`ACCOUNT_DELETION_FAILED` is worth handling explicitly. Owned data is removed
before the account itself, so a mid-way failure leaves the account intact and
the request **safe to retry** — some data will already be gone, and the retry
finishes the job. Offer a retry rather than reporting success.

## Admin-initiated deletion

An admin can delete an account on a support request through
`DELETE /api/admin/users/:id` — see [Admin](admin.md). That path requires a
written reason, which *is* recorded in the audit log, unlike the farmer's own.
