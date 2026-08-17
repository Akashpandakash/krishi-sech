# Fertilizer — `/api/fertilizer`

Fertilizer recommendation for a crop. Source:
[`server/src/fertilizer/`](../../server/src/fertilizer/).

Shared envelope, error codes, and conventions: [README](README.md).
**Requires `Authorization`.**

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/recommendation` | Generate and store a recommendation |

The sibling of [Irrigation](irrigation.md) — same crop selection, same
persistence behaviour, same language rules. The differences are the query
parameters (no `landType`) and the response body.

## GET `/recommendation`

```http
GET /api/fertilizer/recommendation?cropId=b71c0f42-9d38-4e6a-8c25-1a904f7be3d0&language=bn
Authorization: Bearer <accessToken>
```

| Param | Type | Required | Rules |
| --- | --- | --- | --- |
| `cropId` | UUID | | Defaults to the user's current crop |
| `language` | enum | | `bn`, `en`, `hi`. Defaults `en` |

Both optional. Omitting `cropId` selects the *current crop* — the most recently
updated crop that is not `harvested`, falling back to the most recently updated
crop overall. An account with no crops gets `404 CROP_NOT_FOUND`.

`language` defaults to `en`, **not** the farmer's `preferredLanguage`; the
server does not read the profile here. Pass it explicitly.

Response `200`:

```json
{
  "success": true,
  "message": "Fertilizer recommendation generated successfully",
  "data": {
    "id": "c05f9a2d-7e14-4b8c-a396-2fd80b17e654",
    "userId": "0f2b9c4e-1d76-4a30-9c11-8e5d3a7f6b02",
    "cropId": "b71c0f42-9d38-4e6a-8c25-1a904f7be3d0",
    "recommendedFertilizer": "Urea",
    "quantity": { "value": 45, "unit": "kg", "per": "acre" },
    "applicationMethod": "Broadcast evenly over moist soil, then irrigate lightly.",
    "bestApplicationTime": "Early morning before the wind picks up",
    "safetyPrecautions": [
      "Wear gloves and cover your mouth while spreading.",
      "Do not apply within 24 hours of heavy rain."
    ],
    "organicAlternative": "Well-rotted farmyard manure, 2 tonnes per acre",
    "nextRecommendationDate": "2026-09-05T00:00:00.000Z",
    "confidence": 0.72,
    "language": "en",
    "engineVersion": "rules-v1",
    "createdAt": "2026-08-17T11:44:03.221Z"
  }
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `recommendedFertilizer` | string | Product or nutrient name |
| `quantity` | object | `unit` always `kg`, `per` always `acre` |
| `applicationMethod` | string | Pre-localized |
| `bestApplicationTime` | string | Pre-localized |
| `safetyPrecautions` | string[] | Pre-localized. **Render every entry** |
| `organicAlternative` | string | Pre-localized |
| `nextRecommendationDate` | ISO datetime | When to ask again |
| `confidence` | number | 0–1 |

`quantity` is **per acre** regardless of how the crop's land area was recorded.
A crop measured in bigha or katha still gets a per-acre figure, so convert the
area before showing a total dose. Getting this wrong under-doses or over-doses a
real field, so it is worth a unit test.

`safetyPrecautions` is a list and can hold more than one entry. Do not truncate
it to the first item to fit a card — collapse the card instead.

All the prose fields arrive already in the requested `language`. Display them
directly; they are not ARB keys.

## Every call writes a row

Like [Irrigation](irrigation.md), each request generates a fresh recommendation
**and persists it** with a new `id` and `createdAt`. It is a rules engine with a
history log, not a cached read.

Fetch on an explicit action or screen open, hold the result in the controller,
and re-fetch when the crop changes. Polling it fills the history table with
noise.

`engineVersion` is `rules-v1`; the provider boundary lets an AI-backed engine
replace the rules later without changing this response contract.

## Inputs the engine reads

Beyond the query parameters, the engine pulls from the [AI context](ai.md):
current weather, the last recorded fertilizer application, and the last
irrigation. Nothing needs to be sent — the server assembles it.

The last-fertilizer signal is what stops the engine recommending a second dose
days after the first, so advice can legitimately change after the farmer logs an
application.

## Errors

| Status | Code | Meaning |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Non-UUID `cropId` or an unsupported `language` |
| 404 | `CROP_NOT_FOUND` | The `cropId` is not yours, or you have no crops at all |

As with irrigation, `404` conflates "bad ID" with "empty account" — check the
crop list to decide which message to show.
