# Irrigation — `/api/irrigation`

Watering recommendation for a crop. Source:
[`server/src/irrigation/`](../../server/src/irrigation/).

Shared envelope, error codes, and conventions: [README](README.md).
**Requires `Authorization`.**

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/recommendation` | Generate and store a recommendation |

## GET `/recommendation`

```http
GET /api/irrigation/recommendation?cropId=b71c0f42-9d38-4e6a-8c25-1a904f7be3d0&language=bn&landType=irrigated
Authorization: Bearer <accessToken>
```

| Param | Type | Required | Rules |
| --- | --- | --- | --- |
| `cropId` | UUID | | Defaults to the user's current crop |
| `language` | enum | | `bn`, `en`, `hi`. Defaults `en` |
| `landType` | enum | | `upland`, `lowland`, `irrigated`, `rainfed` |

All three are optional, so a bare `GET /api/irrigation/recommendation` is valid.

**`cropId` omitted** selects the *current crop*: the most recently updated crop
that is not `harvested`, falling back to the most recently updated crop overall.
A user with no crops at all gets `404 CROP_NOT_FOUND` — not an empty result — so
gate this screen on a non-empty crop list.

**`landType` omitted** is derived from the crop: `rainfed` when the crop's
`irrigationMethod` is `rainFed`, otherwise `irrigated`. Note the casing — the
crop enum is camelCase `rainFed`, this one is lowercase `rainfed`.

**`language` defaults to `en`**, not to the farmer's `preferredLanguage`. The
server does not read the profile for this. Pass it explicitly or Bengali-reading
farmers get English advice.

Response `200`:

```json
{
  "success": true,
  "message": "Irrigation recommendation generated successfully",
  "data": {
    "id": "7a5e3c81-40bd-4e92-b1f6-9c02d7e845a3",
    "userId": "0f2b9c4e-1d76-4a30-9c11-8e5d3a7f6b02",
    "cropId": "b71c0f42-9d38-4e6a-8c25-1a904f7be3d0",
    "irrigationRequired": true,
    "waterQuantity": { "value": 12000, "unit": "liters", "per": "acre" },
    "bestIrrigationTime": "Early morning, 5–7 AM",
    "irrigationMethod": "flood",
    "nextIrrigationDate": "2026-08-20T00:00:00.000Z",
    "confidence": 0.78,
    "reasoning": "Vegetative stage with no rain forecast and six days since the last irrigation.",
    "language": "en",
    "landType": "irrigated",
    "engineVersion": "rules-v1",
    "createdAt": "2026-08-17T11:40:12.905Z"
  }
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `irrigationRequired` | boolean | The headline answer |
| `waterQuantity` | object | `unit` is always `liters`, `per` always `acre` |
| `bestIrrigationTime` | string | Human-readable, already in `language` |
| `irrigationMethod` | string | Echoes or refines the crop's method |
| `nextIrrigationDate` | ISO datetime | When to check again |
| `confidence` | number | 0–1 |
| `reasoning` | string | Why, in `language` — show it |

`waterQuantity` is **per acre**, regardless of the crop's `landUnit`. A crop
recorded in bigha still gets a per-acre figure, so multiply by the converted
area before displaying a total.

`bestIrrigationTime`, `irrigationMethod`, and `reasoning` are pre-localized
strings from the rules engine — display them as-is, do not run them through the
ARB catalogue.

## Every call writes a row

This is a rules engine plus a history log, not a cached read. Each request
generates a fresh recommendation **and persists it** with a new `id` and
`createdAt`.

So: do not poll it, do not call it on every rebuild, and do not treat it as
idempotent. Fetch on an explicit user action or a screen open, cache the result
in the controller, and re-fetch when the crop or the weather materially changes.

`engineVersion` is `rules-v1` — the provider boundary exists so an AI-backed
implementation can replace the rules engine later without changing this
contract. Display logic should not branch on it, but logging it helps when
advice changes shape between releases.

## Inputs the engine reads

Beyond the query parameters, the engine pulls from the [AI context](ai.md):
current weather (including rain probability), and the last recorded irrigation
activity. Nothing needs to be sent for those — the server assembles them.

The practical consequence is that the same crop can produce different advice an
hour later because the context weather refreshed. That is intended, and it is
another reason not to treat the response as a stable value.

## Errors

| Status | Code | Meaning |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Non-UUID `cropId`, or an unsupported `language`/`landType` |
| 404 | `CROP_NOT_FOUND` | The `cropId` is not yours, or you have no crops at all |

`404` covers two quite different situations — a bad ID and an empty account.
Check the crop list before deciding which message to show.

See [Fertilizer](fertilizer.md) for the sibling endpoint; it follows the same
crop-selection, persistence, and language rules.
