# Notifications — `/api/notifications`

The in-app notification inbox. Source:
[`server/src/broadcasts/`](../../server/src/broadcasts/).

Shared envelope, error codes, and conventions: [README](README.md).
**All routes require `Authorization`.**

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/` | The inbox |
| GET | `/unread-count` | Just the badge number |
| POST | `/:id/read` | Mark one as read |

Notifications are **admin-authored broadcasts**, not per-user events. An admin
composes a message, targets an audience by language, state, or farmer type, and
sends it — see [Admin](admin.md). Nothing in the farmer app creates a
notification, and there is no endpoint to do so.

## Push is best-effort; this inbox is authoritative

FCM delivery can fail silently — a stale token, a device offline for a week, a
handset that dropped the payload. The backend records a broadcast as sent even
when push delivery partly fails, precisely so the message stays readable here.

So the client must **reconcile against this inbox**, not against push receipts:

- Fetch the inbox on app resume and after login, not only when a push arrives.
- Treat a push as a hint to refresh, not as the message itself.
- Never derive the unread badge from push callbacks.

## GET `/`

```http
GET /api/notifications?limit=30
Authorization: Bearer <accessToken>
```

| Param | Type | Required | Rules |
| --- | --- | --- | --- |
| `limit` | integer | | 1–100. Defaults 30 |

Response `200`:

```json
{
  "success": true,
  "message": "Notifications retrieved successfully",
  "data": {
    "notifications": [
      {
        "id": "bc-2026-08-17-monsoon-advisory",
        "title": "Heavy rain expected in Nadia",
        "body": "Delay irrigation for the next two days and check field drainage.",
        "category": "weather",
        "deepLink": "krishisech://weather",
        "sentAt": "2026-08-17T04:30:11.226Z",
        "read": false
      }
    ],
    "unreadCount": 1
  }
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `id` | string | The broadcast ID — use it for the read call |
| `title` | string | 3–80 chars, admin-authored |
| `body` | string | 3–500 chars, admin-authored |
| `category` | enum | `general`, `weather`, `advisory`, `market`, `maintenance` |
| `deepLink` | string, null | An in-app route, or null |
| `sentAt` | ISO datetime | Newest first |
| `read` | boolean | Per-user |

`title` and `body` are written by an admin in whatever language they chose for
that audience. They are **not** localizable by the client — do not attempt to
map them to ARB keys. Targeting by language is how an admin reaches Bengali
readers with Bengali text.

`category` is the app's hook for an icon and grouping.

`deepLink` is an app route to open on tap; treat an unrecognized value as a
plain notification rather than crashing the router.

### `unreadCount` is scoped to the page

The `unreadCount` in this response counts unread items **within the returned
list only** — it is computed from the `limit` you asked for. With
`limit=30` and 40 unread messages, you get `30`.

For a badge, use `/unread-count`, which counts the whole inbox.

## GET `/unread-count`

No parameters. Response `200`:

```json
{
  "success": true,
  "message": "Unread count retrieved successfully",
  "data": { "unreadCount": 7 }
}
```

The cheap call — no message bodies. Use it for the badge on app resume and after
marking items read.

## POST `/:id/read`

```http
POST /api/notifications/bc-2026-08-17-monsoon-advisory/read
Authorization: Bearer <accessToken>
```

Response `200`:

```json
{ "success": true, "message": "Notification marked as read" }
```

No `data`. Idempotent — marking an already-read notification again succeeds and
changes nothing.

It is also idempotent about *nonexistent* broadcasts: the call upserts a read
receipt without checking that the broadcast exists, so an unknown or stale ID
returns `200` rather than `404`. A success here is not proof the notification
was real — do not use it to validate an ID.

There is no mark-all-read endpoint and no unread toggle. "Mark all as read"
means one call per unread item; batch them and refresh the count once at the
end.

## Errors

| Status | Code | Meaning |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | `limit` outside 1–100, or an ID over 100 chars |

There is no `404` on this router. An unknown notification ID succeeds, and an
account with no matching broadcasts gets an empty list, not an error.

## Receiving push

Registering for push is a separate module — see [Devices](devices.md). Without a
registered FCM token the account still receives everything here; it just will
not be woken up for it.

The two obligations that matter: register the token after login and on every FCM
rotation, and unregister on logout. Skip the second and the handset keeps
receiving broadcasts aimed at the previous account.
