# krishi_sech

A smart agriculture platform for farmers, experts and agricultural marketplace.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Backend

The backend uses Node.js, TypeScript, and Express. It lives in `server/`, and
every backend command below runs from that directory.

```bash
cd server
npm install
npm run dev
```

The development server runs at `http://localhost:3000` by default. Verify it
with `GET http://localhost:3000/api/health`.

Available commands:

- `npm run dev` starts the TypeScript development server with file watching.
- `npm run build` compiles TypeScript into `dist/`.
- `npm start` runs the compiled server.
- `npm run db:indexes` creates the MongoDB indexes and unique constraints.
- `npm test` runs the backend tests.

### Database

The backend stores data in MongoDB. Copy `server/.env.example` to
`server/.env` and set
`MONGODB_URI` (optionally `MONGODB_DB_NAME` to override the database named in
the connection string). Collections are created on first write, and the server
ensures indexes on startup; run them explicitly against a deployed database
with:

```bash
npm run build
npm run db:indexes
```

Leaving `MONGODB_URI` unset outside production keeps the backend on in-memory
repositories, which is useful for local UI work but loses all data on restart.
Production startup fails without it.

### Authentication

Set `MONGODB_URI` and replace all JWT and OTP secrets with independent random
values, then start the server:

```bash
npm run dev
```

Authentication endpoints:

- `POST /api/auth/send-otp`
- `POST /api/auth/verify-otp`
- `POST /api/auth/refresh`
- `POST /api/auth/logout`
- `GET /api/auth/me` with `Authorization: Bearer <access-token>`

For local development, request an OTP with:

```bash
curl -X POST http://localhost:3000/api/auth/send-otp \
  -H 'Content-Type: application/json' \
  -d '{"phone":"+919876543210"}'
```

`DEBUG_OTP_ENABLED=true` enables the development response field. Production
configuration validation rejects that flag.

### AI provider

AI chat and crop-disease scanning run through one provider, selected by
`AI_PROVIDER`:

- `gemini` (default) uses `GEMINI_API_KEY` and `GEMINI_MODEL`
  (default `gemini-flash-latest`).
- `openai` uses `OPENAI_API_KEY` and `OPENAI_MODEL`.

Only the selected provider's key is required; production startup fails if it is
missing. Set `AI_ENABLED=false` to disable both AI features, in which case
neither key is needed and the endpoints return `AI_UNAVAILABLE`.

The Gemini image-diagnosis request disables the model's thinking budget: with it
enabled a scan measured 84 seconds and exceeded the 60-second request timeout,
against 10 seconds with it off. A model that cannot disable thinking needs that
value raised in `gemini-completion-provider.ts`.

## Environments

The backend loads the ignored `server/.env` first, then fills missing values
from `server/.env.development`, `server/.env.staging`, or
`server/.env.production` according to `APP_ENV`. These paths resolve from the
working directory, so start the backend from `server/`. Keep real staging and
production files outside Git; use the tracked `.example` files as deployment
templates.

Flutter configuration is supplied at build time:

```bash
# Android emulator
flutter run --dart-define-from-file=config/development.json

# Physical phone on the same Wi-Fi (replace only the URL at invocation time)
flutter run --dart-define-from-file=config/development.json \
  --dart-define=API_BASE_URL=http://MAC_LAN_IP:3000

# Staging
flutter build apk --dart-define-from-file=config/staging.json

# Production (replace the example HTTPS URL before release)
flutter build appbundle --release \
  --dart-define-from-file=config/production.json
```

Staging and production require HTTPS. Production builds also reject localhost,
the Android emulator host, private LAN addresses, demo login, and debug OTP.
No backend secret belongs in a Flutter configuration file.
