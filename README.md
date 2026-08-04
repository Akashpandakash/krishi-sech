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

The backend uses Node.js, TypeScript, and Express.

```bash
npm install
npm run dev
```

The development server runs at `http://localhost:3000` by default. Verify it
with `GET http://localhost:3000/api/health`.

Available commands:

- `npm run dev` starts the TypeScript development server with file watching.
- `npm run build` compiles TypeScript into `dist/`.
- `npm start` runs the compiled server.
- `npm test` runs the backend tests.

### Authentication

Copy `.env.example` to `.env`, set a PostgreSQL `DATABASE_URL`, and replace all
JWT and OTP secrets with independent random values. Then generate the Prisma
client and create the database schema:

```bash
npx prisma generate
npx prisma migrate dev --name authentication
npm run dev
```

Do not run the migration until `DATABASE_URL` points to the intended database.

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

## Environments

The backend loads the existing ignored `.env` first, then fills missing values
from `.env.development`, `.env.staging`, or `.env.production` according to
`APP_ENV`. Keep real staging and production files outside Git; use the tracked
`.example` files as deployment templates.

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
