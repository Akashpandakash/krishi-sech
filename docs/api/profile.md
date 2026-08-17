# Profile — `/api/profile`

The user profile and the farm profile. Source:
[`server/src/profile/`](../../server/src/profile/).

Shared envelope, error codes, and conventions: [README](README.md).
**All routes require `Authorization`.**

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/` | The signed-in user's profile |
| PUT | `/` | Replace the user profile |
| GET | `/farm` | The farm profile, or `null` |
| PUT | `/farm` | Create or replace the farm profile |

Two separate records: the **user** (who they are, what language they read) and
the **farm** (what they grow it on). A user always exists after sign-in; a farm
profile does not exist until it is first saved.

## Both PUT bodies are strict

Unknown keys are rejected, not ignored:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Request validation failed",
    "details": [{ "path": "id", "message": "Unrecognized key: \"id\"" }]
  },
  "requestId": "…"
}
```

So you **cannot round-trip the GET response** — it carries server-owned fields
(`id`, `createdAt`, `updatedAt`, `isActive`, `phone`) that the PUT schema
refuses. Build the request body from your own form state, not from the fetched
object. This is the single most common integration mistake against this module,
and it differs from [Crops](crops.md), where extra keys are silently dropped.

## GET `/`

Response `200`:

```json
{
  "success": true,
  "message": "Profile retrieved successfully",
  "data": {
    "id": "0f2b9c4e-1d76-4a30-9c11-8e5d3a7f6b02",
    "phone": "+919876543210",
    "email": null,
    "googleId": null,
    "name": "Ranjan Das",
    "preferredLanguage": "bn",
    "profilePhotoUrl": null,
    "state": "West Bengal",
    "district": "Nadia",
    "village": "Haringhata",
    "isActive": true,
    "createdAt": "2026-06-15T05:31:44.902Z",
    "updatedAt": "2026-08-17T10:02:07.119Z"
  }
}
```

`phone` is `null` for accounts created through Google sign-in; `email` and
`googleId` are `null` for phone accounts. Never assume `phone` is present.

Returns `404 PROFILE_NOT_FOUND` if the account no longer exists — treat it the
same as a signed-out session.

## PUT `/`

Request:

```json
{
  "name": "Ranjan Das",
  "preferredLanguage": "bn",
  "profilePhotoUrl": null,
  "state": "West Bengal",
  "district": "Nadia",
  "village": "Haringhata"
}
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `name` | string | ✓ | 2–100 chars, trimmed |
| `preferredLanguage` | enum | ✓ | One of the 23 app locales |
| `profilePhotoUrl` | string, null | | Must be a valid URL, max 500 chars |
| `state` | string, null | | Max 120 chars |
| `district` | string, null | | Max 120 chars |
| `village` | string, null | | Max 120 chars |

`preferredLanguage` accepts the full app locale list — `as`, `bn`, `brx`, `doi`,
`gu`, `hi`, `kn`, `ks`, `kok`, `mai`, `ml`, `mni`, `mr`, `ne`, `or`, `pa`, `sa`,
`sat`, `sd`, `ta`, `te`, `ur`, `en`. That is wider than the `bn`/`en`/`hi` the
[AI](ai.md), [Irrigation](irrigation.md), and [Fertilizer](fertilizer.md)
endpoints accept, so a farmer set to `ta` still needs one of those three passed
to the advisory endpoints. Map before sending rather than forwarding
`preferredLanguage` blindly.

`profilePhotoUrl` must be a URL the client already hosts — there is no upload
endpoint in this API.

Response `200` with the updated user, same shape as GET.

## GET `/farm`

Response `200` when set:

```json
{
  "success": true,
  "message": "Farm profile retrieved successfully",
  "data": {
    "id": "e42a7d09-58c6-4f31-b7a0-6d19c3e85f27",
    "userId": "0f2b9c4e-1d76-4a30-9c11-8e5d3a7f6b02",
    "farmName": "Das Family Farm",
    "farmerType": "smallholder",
    "totalLandArea": 4.5,
    "landUnit": "acre",
    "soilType": "alluvial",
    "irrigationSource": "canal",
    "mainCrops": ["Rice", "Potato", "Mustard"],
    "coarseLocation": "Haringhata, Nadia",
    "createdAt": "2026-06-16T04:12:55.318Z",
    "updatedAt": "2026-08-10T09:44:02.660Z"
  }
}
```

Response `200` when never saved:

```json
{
  "success": true,
  "message": "Farm profile retrieved successfully",
  "data": null
}
```

**`data: null` is a success, not an error.** A farmer who has not completed farm
setup is a normal state — route to onboarding rather than showing a failure.

## PUT `/farm`

Upsert: creates the farm profile if absent, replaces it if present.

```json
{
  "farmName": "Das Family Farm",
  "farmerType": "smallholder",
  "totalLandArea": 4.5,
  "landUnit": "acre",
  "soilType": "alluvial",
  "irrigationSource": "canal",
  "mainCrops": ["Rice", "Potato", "Mustard"],
  "coarseLocation": "Haringhata, Nadia"
}
```

| Field | Type | Required | Rules |
| --- | --- | --- | --- |
| `farmName` | string | ✓ | 2–120 chars |
| `farmerType` | string | ✓ | 2–60 chars. **Free text**, not an enum |
| `totalLandArea` | number | ✓ | Positive, max 1,000,000 |
| `landUnit` | string | ✓ | 1–30 chars. **Free text**, not the crop enum |
| `soilType` | string | ✓ | 1–60 chars. **Free text**, not the crop enum |
| `irrigationSource` | string | ✓ | 1–80 chars |
| `mainCrops` | string[] | ✓ | Max 20 entries, each 1–80 chars |
| `coarseLocation` | string, null | | Max 160 chars |

The farm profile's `landUnit`, `soilType`, and `farmerType` are **free text**,
while the same-named fields on a [crop](crops.md) are strict enums. The server
will happily store `"landUnit": "square feet"` here and reject it there. Feed
both from the same picker so the values stay consistent, or aggregate reporting
in the admin panel will fragment.

`coarseLocation` is a human-readable place name, not coordinates. Keep it coarse
— the backend deliberately avoids storing precise GPS anywhere, which is also
why [Weather](weather.md) rounds coordinates before use.

`farmerType` values reach the admin panel's audience filter for
[broadcasts](admin.md), so free text here means a typo silently shrinks a
targeted broadcast's reach.

Response `200` with the saved farm profile, same shape as GET.

## Errors

| Status | Code | Meaning |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Bad field **or an unknown key** — see above |
| 404 | `PROFILE_NOT_FOUND` | The user record is gone; sign out |
