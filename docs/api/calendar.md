# Calendar — `/api/calendar`

Farming tasks with due dates and reminders. Source:
[`server/src/calendar/`](../../server/src/calendar/).

Shared envelope, error codes, and conventions: [README](README.md).
**All routes require `Authorization`.**

| Method | Path | Status | Purpose |
| --- | --- | --- | --- |
| POST | `/tasks` | 201 | Create a task |
| GET | `/tasks` | 200 | List the user's tasks |
| PUT | `/tasks/:id` | 200 | Replace a task |
| DELETE | `/tasks/:id` | 200 | Delete a task |

## The task object

```json
{
  "id": "task-2026-08-20-irrigation-01",
  "userId": "0f2b9c4e-1d76-4a30-9c11-8e5d3a7f6b02",
  "cropId": "b71c0f42-9d38-4e6a-8c25-1a904f7be3d0",
  "taskType": "irrigation",
  "dueDate": "2026-08-20T06:00:00.000Z",
  "status": "pending",
  "notes": "Check the field drain first.",
  "reminderEnabled": true,
  "createdAt": "2026-08-17T11:02:31.774Z",
  "updatedAt": "2026-08-17T11:02:31.774Z"
}
```

### Fields

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `id` | string | ✓ on create | 1–200 chars. **Client-generated** |
| `cropId` | UUID | ✓ | Must be a UUID; not checked against your crops |
| `taskType` | enum | ✓ | `irrigation`, `fertilizer`, `pestInspection`, `harvest` |
| `dueDate` | datetime | ✓ | **Full ISO datetime** — a bare date is rejected |
| `status` | enum | ✓ | `pending`, `completed` |
| `notes` | string or null | | Defaults `null`. Max 2000 chars |
| `reminderEnabled` | boolean | ✓ | No default — send it explicitly |

Two traps here that differ from [Crops](crops.md):

**`dueDate` must be a full datetime.** `"2026-08-20"` fails validation;
`"2026-08-20T06:00:00.000Z"` succeeds. Crops accept a bare date, calendar does
not.

**`cropId` is validated as a UUID but not as *your* UUID.** The server does not
verify the crop exists or belongs to you, so a task can outlive its crop or
point at nothing. Validate the reference client-side and clean up orphaned tasks
after deleting a crop.

## Client-generated IDs

Unlike crops, the task `id` comes from the client on create. That exists so an
offline queue can create a task, reference it locally, and sync later without
waiting for a server-assigned identity.

The consequence: **you own uniqueness**. Use a UUID. Reusing an ID that already
exists is not silently idempotent the way a crop `Idempotency-Key` is — it is a
different code path with no duplicate-key recovery.

The field is a free-form string up to 200 chars rather than a UUID column, so a
readable scheme works too, as long as it cannot collide across devices.

## POST `/tasks`

Request:

```http
POST /api/calendar/tasks
Authorization: Bearer <accessToken>
Content-Type: application/json
```

```json
{
  "id": "3c81f0a7-6d54-4b29-9e07-2fa61b8d5c93",
  "cropId": "b71c0f42-9d38-4e6a-8c25-1a904f7be3d0",
  "taskType": "irrigation",
  "dueDate": "2026-08-20T06:00:00.000Z",
  "status": "pending",
  "notes": null,
  "reminderEnabled": true
}
```

Response `201`:

```json
{
  "success": true,
  "message": "Calendar task created successfully",
  "data": {
    "id": "3c81f0a7-6d54-4b29-9e07-2fa61b8d5c93",
    "userId": "0f2b9c4e-…",
    "cropId": "b71c0f42-…",
    "taskType": "irrigation",
    "dueDate": "2026-08-20T06:00:00.000Z",
    "status": "pending",
    "notes": null,
    "reminderEnabled": true,
    "createdAt": "2026-08-17T11:02:31.774Z",
    "updatedAt": "2026-08-17T11:02:31.774Z"
  }
}
```

## GET `/tasks`

Every task for the user — no filtering, no pagination, no date range. Response
`200`:

```json
{
  "success": true,
  "message": "Calendar tasks retrieved successfully",
  "data": [
    { "id": "3c81f0a7-…", "taskType": "irrigation", "status": "pending", "…": "…" },
    { "id": "9f27b4e0-…", "taskType": "harvest", "status": "completed", "…": "…" }
  ]
}
```

Filter and group by month client-side. For a long-lived account this list only
grows, so the app should prune or archive completed tasks rather than assume it
stays small.

## PUT `/tasks/:id`

Full replacement. The body is the create schema **without `id`** — the ID comes
from the path, and including it in the body is harmless but ignored.

```json
{
  "cropId": "b71c0f42-9d38-4e6a-8c25-1a904f7be3d0",
  "taskType": "irrigation",
  "dueDate": "2026-08-20T06:00:00.000Z",
  "status": "completed",
  "notes": "Done at first light.",
  "reminderEnabled": false
}
```

Response `200` with the updated task. Marking a task done is a full PUT with
`status` flipped — there is no dedicated complete endpoint.

## DELETE `/tasks/:id`

Response `200`:

```json
{ "success": true, "message": "Calendar task deleted successfully" }
```

No `data`.

## Errors

| Status | Code | Meaning |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Bad enum, non-UUID `cropId`, or a bare-date `dueDate` |
| 404 | `CALENDAR_TASK_NOT_FOUND` | No such task **or** it belongs to another user |

## Reminders

`reminderEnabled` is stored and returned, but this module does not schedule
anything. Local notifications are the app's job; server-side push comes from the
broadcast system, which is separate and admin-driven — see
[Notifications](notifications.md).

So a task with `reminderEnabled: true` will produce no notification at all
unless the app schedules one locally. Reschedule on every sync, since the due
date may have moved on another device.

## Relationship to the AI context

Upcoming tasks feed the [AI](ai.md) context as `upcomingTasks`, which is how
the assistant knows what the farmer has planned. Nothing else reads this module.
