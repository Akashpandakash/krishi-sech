# Flutter client

How the app is layered against the API, and what to do when you add an endpoint.

For the endpoints themselves, see the module docs listed in the
[README](README.md).

## Configuration

The base URL and every feature flag are **compiled-in constants** in
[`lib/core/config/app_environment.dart`](../../lib/core/config/app_environment.dart).
There is no dart-define, no `config/*.json`, and no runtime override — edit the
constant and rebuild.

```dart
static const appEnv = 'development';
static const apiBaseUrl = 'https://stage-api.krishisech.com';
static const requestTimeout = Duration(seconds: 25);
```

`AppEnvironment.validate()` still runs at startup and enforces the release
rules: staging and production require HTTPS, and production rejects localhost,
the emulator host, private LAN addresses, demo login, and debug OTP.

Because `appEnv` is now a constant rather than a build flag, **it does not
change itself when you point `apiBaseUrl` at production**. Change both together
or the guard passes on configuration it should have rejected.

## Layering

Feature-first clean architecture. One feature owns one folder under
`lib/features/<feature>/`:

```
data/datasources/remote_*_data_source.dart   HTTP, JSON, envelope unwrapping
data/models/*_model.dart                     fromJson / toEntity
data/repositories/*_repository_impl.dart     caching, offline fallback, retry
domain/entities/                             plain Dart, no JSON
domain/repositories/                         abstract interface
presentation/controllers/                    ChangeNotifier state
presentation/pages/                          widgets
```

The rule that keeps this honest: **entities never know about JSON, and widgets
never know about HTTP**. A `Crop` entity has no `fromJson`; a page never sees a
status code. Everything in between is the model and repository layers' job.

There is no DI container. Construction happens in
[`lib/main.dart`](../../lib/main.dart), and controllers reach widgets through an
inherited scope such as
[`auth_scope.dart`](../../lib/features/login/presentation/auth_scope.dart).

## Adding an endpoint

Work outward, one layer at a time:

1. **Entity** — a plain Dart class in `domain/entities/`. No JSON.
2. **Repository interface** — the abstract method in `domain/repositories/`,
   phrased in entities and typed failures.
3. **Model** — `fromJson` plus `toEntity` in `data/models/`. Parse dates with
   `DateTime.parse(...).toUtc()`.
4. **Data source** — the HTTP call in `data/datasources/`. Copy an existing one.
5. **Repository impl** — caching, offline fallback, and the token refresh retry.
6. **Controller** — `ChangeNotifier` state for the page.
7. **Wiring** — construct it in `main.dart` and expose it through a scope.

Do not shortcut by calling a data source from a widget. The layer that looks
redundant on the first endpoint is what makes the fifth one testable.

## Data source conventions

Every remote data source follows the same shape, so copy the fullest example —
[`remote_crop_data_source.dart`](../../lib/features/my_crop/data/datasources/remote_crop_data_source.dart)
— rather than starting fresh.

**Timeout.** `.timeout(AppEnvironment.requestTimeout)` on every call — 25
seconds. Catch `TimeoutException` and map it to a typed timeout failure;
catch `SocketException` and map it to offline. An uncaught either one surfaces
to the user as a raw Dart exception.

**Envelope.** Unwrap `data` from the response body. Remember `data` is absent on
deletes and logout, and legitimately `null` on `GET /api/profile/farm` — see
[Profile](profile.md).

**Errors.** Map `error.code` to a typed failure. Never match on `error.message`;
in production every 5xx message is replaced with a generic string.

**Auth.** Attach `Authorization: Bearer <accessToken>`. On `401 TOKEN_INVALID`,
refresh once and replay — see the retry rule in [Auth](auth.md) and the
implementation in
[`auth_repository_impl.dart`](../../lib/features/login/data/repositories/auth_repository_impl.dart).
Cap the retry at one attempt and serialize concurrent refreshes behind a
single-flight lock, or a burst of parallel 401s each rotates the refresh token
and all but one fails.

**Dates.** `DateTime.parse(value).toUtc()` on the way in. Send ISO-8601 UTC on
the way out — and check whether the endpoint wants a bare date or a full
datetime, since [Crops](crops.md) accepts both while [Calendar](calendar.md)
requires a datetime.

## Failure types

`AuthFailureType` in
[`auth_repository.dart`](../../lib/features/login/domain/repositories/auth_repository.dart)
is the shared vocabulary: `offline`, `timeout`, `validation`, `unauthorized`,
`server`.

The distinction that matters to a farmer on a patchy rural connection is
`offline` and `timeout` versus the rest. Those two mean "try again" and should
keep the screen's cached data visible; the others mean something is actually
wrong. Do not collapse them into one generic error state.

## Offline behaviour

Repository implementations own caching and fallback — not data sources, not
controllers. A data source either returns data or throws.

Worth knowing per module:

- [Weather](weather.md) fails transiently and often. Keep the last reading with
  its `updatedAt` and show that rather than an error screen.
- [Notifications](notifications.md) must be reconciled against the server inbox
  on resume, since push delivery is best-effort.
- [Crops](crops.md) creation is safe to retry **only** when you send an
  `Idempotency-Key` — generate the UUID before the first attempt.
- [Calendar](calendar.md) tasks carry a client-generated `id`, which is what
  lets an offline queue create one and sync it later.

## Testing

`flutter test` runs the app suite; `npm test` in `server/` runs the backend.
Environment guards have their own coverage in
[`test/core/app_environment_test.dart`](../../test/core/app_environment_test.dart)
— `validateValues` is exposed with `@visibleForTesting` precisely so the release
rules can be tested without building for release.
