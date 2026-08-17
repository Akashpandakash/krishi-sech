# Mandi — `/api/mandi`

Market price quotes, sourced from AGMARKNET (data.gov.in) with admin-entered
rows as a fallback. Source: [`server/src/mandi/`](../../server/src/mandi/).

Shared envelope, error codes, and conventions: [README](README.md).
**Requires `Authorization`.**

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/prices` | Latest quotes for a state |

This router is **optionally mounted** — deployments without a mandi price
provider answer `404 NOT_FOUND` for the whole path. Treat that as "feature
unavailable" and hide the Market price tab.

The endpoint is authenticated even though mandi prices are public data: every
cache miss costs a call against the shared data.gov.in quota, and the tab sits
behind login anyway.

## GET `/prices`

```http
GET /api/mandi/prices?state=West%20Bengal&district=Nadia&commodity=Rice
Authorization: Bearer <accessToken>
```

| Param | Type | Required | Rules |
| --- | --- | --- | --- |
| `state` | string | **✓** | 1–80 chars |
| `district` | string | | 1–80 chars |
| `commodity` | string | | 1–80 chars |

**`state` is required** — there is no all-India query. Omitting it is a
`VALIDATION_ERROR`, so the UI needs a state selected before it can ask.

All three are restricted to letters, digits, spaces, and `.,'()-&`. They are
echoed into an upstream query string, which is why the character set is tight. A
market name with an unusual character will be rejected rather than escaped:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [
      { "path": "district", "message": "contains unsupported characters" }
    ]
  },
  "requestId": "…"
}
```

Response `200`:

```json
{
  "success": true,
  "message": "Mandi prices retrieved successfully",
  "data": {
    "prices": [
      {
        "id": "west bengal|nadia|ranaghat|rice|swarna|2026-08-17",
        "seriesKey": "west bengal|nadia|ranaghat|rice|swarna",
        "state": "West Bengal",
        "district": "Nadia",
        "market": "Ranaghat",
        "commodity": "Rice",
        "variety": "Swarna",
        "grade": "FAQ",
        "arrivalDate": "2026-08-17T00:00:00.000Z",
        "minPrice": 2100,
        "maxPrice": 2450,
        "modalPrice": 2300,
        "source": "agmarknet",
        "recordedAt": "2026-08-17T06:15:02.338Z"
      }
    ],
    "count": 1,
    "live": true
  }
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `state`, `district`, `market` | string | Where |
| `commodity` | string | What |
| `variety`, `grade` | string, **null** | Often absent upstream |
| `arrivalDate` | ISO datetime | Normalized to UTC midnight — a **date**, not a moment |
| `minPrice`, `maxPrice`, `modalPrice` | integer | **Rupees per quintal** |
| `source` | enum | `agmarknet` or `manual` |
| `seriesKey` | string | Identifies one market + produce across days |
| `recordedAt` | ISO datetime | When this row was stored |

Prices are **whole rupees per quintal** (100 kg). Farmers usually think in
rupees per kg or per maund, so convert for display rather than showing the raw
figure.

`modalPrice` — the most common transacted price — is the headline number.
`minPrice`/`maxPrice` are the day's range, not a forecast.

`arrivalDate` is a calendar date stored at UTC midnight. Render it as a date; as
a local timestamp it shows the previous evening in IST.

## `count` and `live` are different signals

The two flags at the bottom of the response are easy to conflate and mean quite
different things.

**`count: 0`** is a legitimate answer. A district may simply have had no
arrivals that day — no market activity, no quotes. Show "no arrivals reported",
not an error.

**`live: false`** means AGMARKNET is unreachable and the rows you got are
admin-entered (`source: "manual"`) only. They are real prices, but an incomplete
picture. **Label them in the UI** — a farmer comparing two markets needs to know
one of them may be missing rather than cheap.

The combinations:

| `count` | `live` | Meaning |
| --- | --- | --- |
| > 0 | `true` | Normal — the full feed |
| 0 | `true` | Feed is up, genuinely no arrivals for this filter |
| > 0 | `false` | Feed is down; showing admin-entered rows, incomplete |
| 0 | `false` | Feed is down and nothing was entered manually |

## Price history

Quotes are persisted rather than proxied straight through, because the upstream
feed only ever publishes the current day's snapshot. `seriesKey` identifies one
continuous series — same state, district, market, commodity, and variety — so a
trend is a comparison of two points on the same key.

There is no history or trend endpoint in the farmer API yet. The persistence
exists so one can be added; today the app sees one day at a time.

`id` is derived from the series and the arrival date, which makes a re-fetch of
the same day idempotent rather than duplicating rows.

## Errors

| Status | Code | Meaning |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Missing `state`, or a filter with unsupported characters |
| 404 | `NOT_FOUND` | The router is not mounted on this deployment |

Upstream failures do **not** surface as errors — they surface as `live: false`
with whatever manual rows exist. There is no error code to catch for "AGMARKNET
is down"; check the flag.

Admins manage the manual rows and browse the feed through
[`/api/admin/mandi`](admin.md).
