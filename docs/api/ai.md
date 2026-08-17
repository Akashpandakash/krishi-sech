# AI — `/api/ai`

Farming context, the assistant chat, and crop disease scanning. Source:
[`server/src/ai/`](../../server/src/ai/).

Shared envelope, error codes, and conventions: [README](README.md).
**All routes require `Authorization`.**

| Method | Path | Mounted when | Purpose |
| --- | --- | --- | --- |
| GET | `/context` | always | Everything the assistant knows about the farmer |
| POST | `/chat` | a completion provider is configured | Ask a question |
| POST | `/disease-scan` | a vision provider is configured | Diagnose a crop photo |

The whole router is rate-limited per IP by `AI_RATE_LIMIT_MAX` over
`RATE_LIMIT_WINDOW_MS` — a tighter budget than the rest of the API, because
every call costs provider tokens.

`/chat` and `/disease-scan` are **optionally mounted**. On a deployment without
the corresponding provider they answer `404 NOT_FOUND`, indistinguishable from a
typo'd path. Treat a 404 on these two as "feature unavailable" and hide the
entry point rather than showing an error.

## GET `/context`

No parameters. Response `200`:

```json
{
  "success": true,
  "message": "AI context retrieved successfully",
  "data": {
    "user": {
      "id": "0f2b9c4e-1d76-4a30-9c11-8e5d3a7f6b02",
      "name": "Ranjan Das",
      "preferredLanguage": "bn"
    },
    "location": {
      "city": "Haringhata",
      "district": "Nadia",
      "state": "West Bengal",
      "country": "India",
      "latitude": 22.96,
      "longitude": 88.57
    },
    "currentWeather": {
      "temperatureCelsius": 31.4,
      "condition": "Light rain",
      "humidityPercent": 78,
      "windSpeedKmh": 12.6,
      "rainProbabilityPercent": 65,
      "updatedAt": "2026-08-17T09:00:00.000Z"
    },
    "crops": [{ "id": "b71c0f42-…", "cropName": "Rice", "…": "…" }],
    "currentCrop": { "id": "b71c0f42-…", "cropName": "Rice", "…": "…" },
    "growthStage": "vegetative",
    "cropHealth": "healthy",
    "upcomingTasks": [
      {
        "id": "3c81f0a7-…",
        "cropId": "b71c0f42-…",
        "title": "Irrigation",
        "taskType": "irrigation",
        "dueAt": "2026-08-20T06:00:00.000Z"
      }
    ],
    "lastIrrigation": {
      "cropId": "b71c0f42-…",
      "occurredAt": "2026-08-11T05:40:00.000Z",
      "details": "Flood, full field"
    },
    "lastFertilizer": null,
    "recentDiseaseScans": [
      {
        "scanId": "5b1e08a7-…",
        "cropId": "b71c0f42-…",
        "possibleDisease": "Bacterial leaf blight",
        "confidence": 0.81,
        "severity": "medium",
        "createdAt": "2026-08-14T07:22:19.004Z"
      }
    ],
    "generatedAt": "2026-08-17T11:52:44.610Z"
  }
}
```

`location`, `currentWeather`, `currentCrop`, `lastIrrigation`, and
`lastFertilizer` are all nullable. `crops`, `upcomingTasks`, and
`recentDiseaseScans` are arrays that can be empty.

`currentCrop` is the most recently updated crop that is not `harvested`, falling
back to the most recently updated crop overall — the same selection
[Irrigation](irrigation.md) and [Fertilizer](fertilizer.md) use when `cropId` is
omitted. `growthStage` and `cropHealth` are conveniences copied off it.

**You rarely need this endpoint.** `/chat` and `/disease-scan` assemble the same
context server-side, so there is nothing to send and no reason to fetch it
first. It exists for a debug screen and for understanding what the assistant can
see. Returns `404 USER_NOT_FOUND` for a deleted or deactivated account.

## POST `/chat`

Request:

```http
POST /api/ai/chat
Authorization: Bearer <accessToken>
Content-Type: application/json
```

```json
{
  "message": "ধানের পাতা হলুদ হয়ে যাচ্ছে, কী করব?",
  "language": "bn",
  "history": [
    { "role": "user", "content": "আমার জমিতে কখন সেচ দেব?" },
    { "role": "assistant", "content": "আগামী দুই দিন বৃষ্টির সম্ভাবনা…" }
  ]
}
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `message` | string | ✓ | 1–2000 chars, trimmed |
| `language` | enum | | `bn`, `en`, `hi`. **Defaults `bn`** |
| `history` | array | | Max 12 entries. Defaults `[]` |

Each `history` entry is `{ role: "user" | "assistant", content: string }` with
`content` 1–2000 chars. `system` is not accepted — the server owns the system
prompt.

Response `200`:

```json
{
  "success": true,
  "message": "AI response generated successfully",
  "data": {
    "reply": "পাতা হলুদ হওয়ার সাধারণ কারণ নাইট্রোজেনের ঘাটতি…",
    "language": "bn",
    "model": "gemini-2.0-flash",
    "usage": { "inputTokens": 1284, "outputTokens": 213, "totalTokens": 1497 }
  }
}
```

`usage` is `null` when the provider does not report it. `model` is the provider's
model ID, useful in logs when answer quality shifts.

### The client owns the transcript

The server keeps **no conversation state**. Every request is independent, and
`history` is the only memory the model has.

That puts three jobs on the client:

- Append each exchange to a local transcript and send the tail with the next
  message.
- Trim to the last 12 entries before sending, or the request fails validation.
- Drop or summarize long turns — 12 entries at 2000 chars each is a large prompt
  on every call, and the whole context blob is prepended on top of it.

`language` defaults to **`bn`**, not `en` and not the farmer's
`preferredLanguage`. It also accepts only three of the app's 23 locales, so map
`preferredLanguage` down before sending rather than forwarding it.

The system prompt instructs the model to ground answers in the farmer's crop,
growth stage, location, weather, and history, and to answer in the requested
language. No context needs to be included in `message`.

## POST `/disease-scan`

`multipart/form-data`, not JSON.

```http
POST /api/ai/disease-scan
Authorization: Bearer <accessToken>
Content-Type: multipart/form-data; boundary=…
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `image` | file | ✓ | JPEG, PNG, or WebP. **Max 2 MB. Exactly one file** |
| `language` | text | | `bn`, `en`, `hi`. Anything else **silently** falls back to `en` |

Note the asymmetry: an unsupported `language` here is not a validation error the
way it is on `/chat` — it is quietly coerced to `en`. Send a valid value; a typo
will not tell you.

Response `200`:

```json
{
  "success": true,
  "message": "Crop image analyzed successfully",
  "data": {
    "scanId": "5b1e08a7-3c92-4d61-bf05-8a27e4931cd6",
    "crop": "Rice",
    "disease": "Bacterial leaf blight",
    "confidence": 0.81,
    "severity": "medium",
    "symptoms": [
      "Water-soaked lesions along the leaf margins",
      "Yellowing that spreads from the tip downward"
    ],
    "treatment": [
      "Drain the field for two days to slow spread.",
      "Remove and burn severely affected leaves."
    ],
    "medicine": ["Copper oxychloride 50% WP, 2 g per litre"],
    "organicAlternative": ["Neem oil spray at 5 ml per litre, weekly"],
    "prevention": [
      "Avoid excess nitrogen during the vegetative stage.",
      "Use certified disease-free seed next season."
    ],
    "expertConsultationRecommended": true,
    "createdAt": "2026-08-17T12:03:57.842Z"
  }
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `scanId` | UUID | Generated per scan |
| `crop` | string | What the model saw, which may differ from the recorded crop |
| `disease` | string | Diagnosis |
| `confidence` | number | 0–1 |
| `severity` | enum | `low`, `medium`, `high` |
| `symptoms` | string[] | Pre-localized |
| `treatment` | string[] | Pre-localized |
| `medicine` | string[] | Pre-localized. Chemical products — see below |
| `organicAlternative` | string[] | Pre-localized |
| `prevention` | string[] | Pre-localized |
| `expertConsultationRecommended` | boolean | Surface prominently when true |

Every list can be empty. All the prose is already in the requested language.

`medicine` names real agrochemicals with dosages. Pair it with
`expertConsultationRecommended` and `confidence` in the UI rather than
presenting a low-confidence chemical recommendation as settled advice.

### Performance and failure

This is the slowest endpoint in the API by a wide margin — an image upload plus
a vision model round-trip. Budget for the client's full 25-second timeout, show
real progress, and do not block the rest of the screen.

The scan degrades rather than fails when the context store is unavailable: the
diagnosis proceeds without farm context. If the vision provider itself fails,
the request errors.

### Errors

| Status | Code | Meaning |
| --- | --- | --- |
| 400 | `IMAGE_REQUIRED` | No `image` field in the form |
| 400 | `INVALID_IMAGE_TYPE` | Not JPEG, PNG, or WebP |
| 413 | `IMAGE_TOO_LARGE` | Over 2 MB |
| 400 | `UPLOAD_ERROR` | Malformed multipart, or more than one file |

Compress and resize client-side before uploading. A modern phone camera clears
2 MB easily, so a scan that works in testing will fail in the field without
downscaling. Check the size *after* compression and surface a clear message
rather than letting the 413 surprise the farmer.
