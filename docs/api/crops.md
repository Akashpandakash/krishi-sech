# Crops — `/api/crops`

The farmer's crop records. Source:
[`server/src/crops/`](../../server/src/crops/).

Shared envelope, error codes, and conventions: [README](README.md).
**All routes require `Authorization`.**

| Method | Path | Status | Purpose |
| --- | --- | --- | --- |
| POST | `/` | 201 | Create a crop |
| GET | `/` | 200 | List the user's crops, newest first |
| GET | `/:id` | 200 | One crop |
| PUT | `/:id` | 200 | Replace a crop |
| DELETE | `/:id` | 200 | Delete a crop |

`:id` must be a UUID; anything else is a `VALIDATION_ERROR` rather than a 404.

## The crop object

```json
{
  "id": "b71c0f42-9d38-4e6a-8c25-1a904f7be3d0",
  "userId": "0f2b9c4e-1d76-4a30-9c11-8e5d3a7f6b02",
  "cropName": "Rice",
  "variety": "Swarna",
  "sowingDate": "2026-06-15T00:00:00.000Z",
  "growthStage": "vegetative",
  "landArea": 2.5,
  "landUnit": "acre",
  "soilType": "alluvial",
  "irrigationMethod": "flood",
  "expectedHarvestDate": "2026-11-01T00:00:00.000Z",
  "healthStatus": "healthy",
  "notes": "Transplanted from the north seedbed.",
  "createdAt": "2026-06-15T05:31:44.902Z",
  "updatedAt": "2026-08-02T11:20:08.517Z"
}
```

`id`, `userId`, `createdAt`, and `updatedAt` are server-owned. Never send them
in a request body — `POST` and `PUT` ignore unknown keys, so a round-tripped
object will silently *not* do what it looks like it does.

### Fields

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `cropName` | string | ✓ | 1–100 chars, trimmed |
| `variety` | string | ✓ | 1–100 chars, trimmed |
| `sowingDate` | date or datetime | ✓ | **Cannot be in the future** |
| `growthStage` | enum | ✓ | `sowing`, `germination`, `seedling`, `vegetative`, `flowering`, `fruiting`, `maturity`, `harvested` |
| `landArea` | number | ✓ | Positive and finite |
| `landUnit` | enum | ✓ | `acre`, `hectare`, `bigha`, `katha` |
| `soilType` | enum | ✓ | `alluvial`, `black`, `red`, `laterite`, `sandy`, `clay`, `loamy`, `other` |
| `irrigationMethod` | enum | ✓ | `drip`, `sprinkler`, `flood`, `rainFed`, `manual` |
| `expectedHarvestDate` | date, datetime, or null | | Defaults `null`. Cannot precede `sowingDate` |
| `healthStatus` | enum | | Defaults `healthy`. `healthy`, `moderate`, `needsAttention` |
| `notes` | string or null | | Defaults `null`. Max 2000 chars |

Dates accept both `"2026-06-15"` and `"2026-06-15T05:30:00.000Z"`, and always
come back as full ISO datetimes. A bare date is stored as UTC midnight, so a
farmer in IST who sows on the 15th and sends `"2026-06-15"` gets back
`2026-06-15T00:00:00.000Z` — correct as a calendar date, five and a half hours
"early" if you render it as a local timestamp.

Note the casing: `rainFed` is camelCase here. The [Irrigation](irrigation.md)
module's `landType` uses lowercase `rainfed`, and they are different enums.

## POST `/`

Request:

```http
POST /api/crops
Authorization: Bearer <accessToken>
Content-Type: application/json
Idempotency-Key: 9c4e7f10-2b8d-4a63-b5e1-70c8a2f96d34
```

```json
{
  "cropName": "Rice",
  "variety": "Swarna",
  "sowingDate": "2026-06-15",
  "growthStage": "vegetative",
  "landArea": 2.5,
  "landUnit": "acre",
  "soilType": "alluvial",
  "irrigationMethod": "flood",
  "expectedHarvestDate": "2026-11-01",
  "healthStatus": "healthy",
  "notes": null
}
```

Response `201`:

```json
{
  "success": true,
  "message": "Crop created successfully",
  "data": { "id": "9c4e7f10-2b8d-4a63-b5e1-70c8a2f96d34", "…": "…" }
}
```

### Idempotency

The optional `Idempotency-Key` header holds a UUID, and **it becomes the crop's
`id`**. A retry with the same key hits a duplicate-key insert and returns the
existing crop instead of creating a second one.

So: generate the UUID client-side *before* the first attempt, reuse it for every
retry of that create, and expect `data.id` to equal the key you sent. This is
what makes a create safe to retry after a timeout, where the request may well
have succeeded before the connection dropped.

Omit the header and the server assigns a random UUID — at which case a timeout
retry produces a duplicate crop.

The header itself must be a valid UUID; a random string is a `VALIDATION_ERROR`.

## GET `/`

Response `200` — a bare array in `data`, newest first by `createdAt`:

```json
{
  "success": true,
  "message": "Crops retrieved successfully",
  "data": [
    { "id": "b71c0f42-…", "cropName": "Rice", "…": "…" },
    { "id": "3d8a5e91-…", "cropName": "Potato", "…": "…" }
  ]
}
```

An empty list is `"data": []`, never `null`.

## GET `/:id`

Response `200` with a single crop object, or `404 CROP_NOT_FOUND`.

## PUT `/:id`

**Full replacement, not a patch.** The body is the same schema as `POST` and
every required field must be present — sending only `{ "healthStatus":
"needsAttention" }` fails validation rather than partially updating.

To change one field, take the crop you already hold, strip the server-owned
keys, apply the change, and send the whole thing.

Response `200` with the updated crop. `updatedAt` moves; `createdAt` does not.

## DELETE `/:id`

Response `200`:

```json
{ "success": true, "message": "Crop deleted successfully" }
```

No `data`. Deleting a crop does **not** cascade to its calendar tasks — tasks
referencing the dead `cropId` remain and must be cleaned up by the client. See
[Calendar](calendar.md).

## Errors

| Status | Code | Meaning |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Bad field, future `sowingDate`, or harvest before sowing |
| 404 | `CROP_NOT_FOUND` | No such crop **or** it belongs to another user |

A validation failure names the field:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [
      { "path": "sowingDate", "message": "Sowing date cannot be in the future" }
    ]
  },
  "requestId": "…"
}
```

## Downstream effects

The crop list drives more than the crop screen. [Irrigation](irrigation.md),
[Fertilizer](fertilizer.md), and the [AI](ai.md) context all fall back to the
user's *current crop* when no `cropId` is given — the most recently updated
crop that is not `harvested`, or the most recently updated crop overall if every
one has been harvested.

That means marking a crop `harvested` silently changes which crop the
recommendation endpoints answer for, and a user with no crops at all gets
`404 CROP_NOT_FOUND` from those endpoints rather than an empty result.
