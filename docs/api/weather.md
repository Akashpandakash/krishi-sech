# Weather — `/api/weather`

Current conditions and today's forecast, proxied from Open-Meteo. Source:
[`server/src/weather/`](../../server/src/weather/).

Shared envelope, error codes, and conventions: [README](README.md).

| Method | Path | Auth | Purpose |
| --- | --- | --- | --- |
| GET | `/current` | **none** | Current weather for a coordinate |

This is the only farmer-facing data route with **no authentication**. It takes
coordinates as query parameters rather than reading a stored location, so it
works on the splash screen before sign-in.

## GET `/current`

```http
GET /api/weather/current?lat=22.57&lng=88.36&language=bn
```

| Param | Type | Required | Rules |
| --- | --- | --- | --- |
| `lat` | number | ✓ | −90 to 90 |
| `lng` | number | ✓ | −180 to 180 |
| `language` | enum | | `bn`, `en`, `hi` |

`language` is accepted and validated but does not change the response — every
field is numeric, and the labels are the app's job. Do not expect a translated
condition string.

Response `200`:

```json
{
  "success": true,
  "message": "Current weather retrieved successfully",
  "data": {
    "temperatureCelsius": 31.4,
    "weatherCode": 61,
    "humidityPercent": 78,
    "windSpeedKmh": 12.6,
    "feelsLikeCelsius": 36.1,
    "rainProbabilityPercent": 65,
    "minimumTemperatureCelsius": 26.2,
    "maximumTemperatureCelsius": 33.8,
    "updatedAt": "2026-08-17T09:00:00.000Z"
  }
}
```

| Field | Type | Notes |
| --- | --- | --- |
| `temperatureCelsius` | number | Always present |
| `weatherCode` | number | WMO code — map to icon and localized label |
| `humidityPercent` | number | Always present |
| `windSpeedKmh` | number | Always present |
| `feelsLikeCelsius` | number, **null** | Apparent temperature |
| `rainProbabilityPercent` | number, **null** | Today's maximum |
| `minimumTemperatureCelsius` | number, **null** | Today's low |
| `maximumTemperatureCelsius` | number, **null** | Today's high |
| `updatedAt` | ISO datetime | When the reading was taken |

The four nullable fields are genuinely absent sometimes — Open-Meteo does not
always return the daily block. **Render a placeholder, never a default of
zero**: a missing rain probability shown as `0%` tells a farmer it will not rain.

The four non-nullable fields are guaranteed. If upstream omits any of them the
backend fails the whole request with `WEATHER_INVALID_RESPONSE` rather than
returning a partial reading.

## Coordinate privacy

Coordinates are rounded to **two decimal places** server-side before they reach
Open-Meteo — roughly a kilometre, enough for a forecast and not enough to locate
a farm. Send coarse coordinates from the app as well; there is no reason to
transmit GPS precision that the backend immediately discards.

The same instinct runs through the rest of the API: the farm profile stores a
`coarseLocation` string rather than a point, and the [AI](ai.md) context reports
city/district/state.

## Errors

| Status | Code | Meaning |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | Missing or out-of-range `lat`/`lng` |
| 502 | `WEATHER_UPSTREAM_ERROR` | Open-Meteo returned a non-200 or was unreachable |
| 504 | `WEATHER_TIMEOUT` | Open-Meteo did not answer within 10 seconds |
| 502 | `WEATHER_INVALID_RESPONSE` | Upstream answered but omitted a required field |

All four upstream failures are transient and none of them are the user's fault.
Show the last known reading with its `updatedAt` rather than an error screen,
and retry on the next foreground.

The backend applies its own 10-second timeout to Open-Meteo, well inside the
client's 25-second request timeout, so a `WEATHER_TIMEOUT` arrives as a proper
JSON error rather than a client-side `TimeoutException`.

## Caching

Responses carry `Cache-Control: no-store` like everything else in this API, so
nothing is cached in transit. The weather controller in the app holds the last
reading and refreshes on a timer — see
[`weather_controller.dart`](../../lib/features/weather/presentation/controllers/weather_controller.dart).

Weather also reaches the advisory endpoints indirectly: the [AI](ai.md) context
carries a `currentWeather` block, and both [Irrigation](irrigation.md) and
[Fertilizer](fertilizer.md) read it — rain probability is what makes an
irrigation recommendation say "skip today". That context weather comes from the
context store rather than a live call to this endpoint, so the two can differ.
