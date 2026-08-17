# Krishi Sech production deployment plan

This directory is the deployment runbook for the backend and Flutter release. It does not deploy resources or contain credentials.

## Recommended topology

Use the managed-hosting plan for RC1: one staging web service and database, plus one production web service and database, in the closest available region to Indian users. MongoDB is hosted separately from the web services (MongoDB Atlas is the reference choice). A managed platform reduces operating-system, TLS, database-backup, and rollback work. Use the VPS plan only if the team has an operator who can own patching, monitoring, backups, and recovery.

| Environment | Flutter API URL | Backend | Database |
| --- | --- | --- | --- |
| Development | Existing local/LAN strategy | Local Node process | Local MongoDB |
| Staging | `https://staging-api.krishisech.com` | Separate service | Separate staging database |
| Production | `https://api.krishisech.com` | Separate service | Separate production database |

Never share a database or credentials between staging and production. The OpenAI key and all other secrets remain backend-only.

## DNS records

For managed hosting, create `CNAME` records for `api` and `staging-api` pointing to the distinct hostnames supplied by the platform, then complete domain verification there. For a VPS, create `A` records for `api` and `staging-api` pointing to their public IPv4 addresses; add `AAAA` only when IPv6 is configured and firewalled. An optional `CAA` record can authorize `letsencrypt.org`. Use a 300-second TTL during cutover and raise it after validation. No DNS record should expose a database host.

## Planning estimate (USD/month, before tax and usage APIs)

- Railway alternative: the production-oriented Pro subscription begins at $20/month and includes a matching usage credit; CPU, memory, storage, and egress above that are usage billed. Isolated staging adds its own resource use.
- VPS baseline: a 2 GiB VM is about $12, daily VM backup about $3.60, and optional object storage about $5. A separate staging VM adds $6–12. Self-hosted MongoDB has no license fee but substantially increases operator responsibility; managed MongoDB starts around $15 on the cited comparison provider.
- Variable services are additional: domain registration, SMS/OTP traffic, OpenAI tokens, monitoring/alerting upgrades, database growth, and outbound bandwidth.

## Runtime contract

- Node.js: pin Node 24 LTS (the package declares `>=22`). Node 20 fails on both counts: `firebase-admin@14` requires `>=22`, and the npm 10 it bundles cannot install `server/package-lock.json` — it reports gcp-metadata, gaxios and node-fetch as missing. npm 11 or newer is required for `npm ci`.
- Install/build: `npm ci && npm run build` (from `server/`)
- Database index setup: `npm run db:indexes`
- Start: `npm start`
- Hosted bind: `HOST=0.0.0.0` and the platform-supplied `PORT`.
- Liveness: `GET /api/health`
- Readiness: `GET /api/ready`

`/api/health` proves that Express is serving. `/api/ready` additionally reports configuration validation and performs a time-bounded MongoDB ping. Responses do not reveal database addresses, secrets, stack traces, or topology. Route platform health checks to `/api/ready` so an instance is not admitted while its database is unavailable.

## Required backend environment variable names

- `APP_ENV`, `NODE_ENV`, `HOST`, `PORT`
- `MONGODB_URI`, `MONGODB_DB_NAME`
- `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `OTP_HASH_SECRET`
- `REQUEST_TIMEOUT_MS`
- `LOGGING_ENABLED`, `DEMO_LOGIN_ENABLED`, `DEBUG_OTP_ENABLED`
- `AI_PROVIDER` (`gemini` or `openai`), `AI_ENABLED`, and the selected provider's key: `GEMINI_API_KEY`/`GEMINI_MODEL` or `OPENAI_API_KEY`/`OPENAI_MODEL`
- `WEATHER_PROVIDER`, `WEATHER_API_BASE_URL`
- `TRUST_PROXY`, `CORS_ALLOWED_ORIGINS`
- `RATE_LIMIT_WINDOW_MS`, `AUTH_RATE_LIMIT_MAX`, `AI_RATE_LIMIT_MAX`
- `OTP_REQUEST_WINDOW_SECONDS`, `OTP_MAX_REQUESTS_PER_WINDOW`
- `FAST2SMS_API_KEY`, `FAST2SMS_SENDER_ID`, `FAST2SMS_ROUTE` outside development

Production must set `LOGGING_ENABLED=false`, `DEMO_LOGIN_ENABLED=false`, and `DEBUG_OTP_ENABLED=false`. `CORS_ALLOWED_ORIGINS` must contain only exact approved HTTPS browser origins and never `*`. Native Flutter requests do not require a browser Origin header. Set `TRUST_PROXY=true` only behind the single trusted platform or Nginx proxy in these runbooks.

Use the platform secret store or a root-readable environment file outside the checkout. Do not copy `.env`, API keys, token secrets, or database URLs into Git, Flutter assets, build arguments, logs, screenshots, or support tickets.

## Release gate

1. Provision isolated staging resources and DNS.
2. Set variables in the host secret store; validate names against `server/.env.staging.example` without copying values into the repository.
3. From `server/`, run `npm ci`, `npm test`, `npm run build`, then `npm run db:indexes` against staging.
4. Verify health/readiness, login/refresh/logout, weather, calendar, recommendations, AI chat, and disease scanning.
5. Confirm error responses have a request ID and contain no stack trace or secret.
6. Set `appEnv`/`apiBaseUrl` in `lib/core/config/app_environment.dart` to the staging values, build the app, and complete a physical-device smoke test.
7. Take a production database snapshot, deploy the reviewed commit, run `npm run db:indexes` once, and wait for readiness.
8. Set `appEnv`/`apiBaseUrl` in `lib/core/config/app_environment.dart` to the production values and build; the startup guard rejects HTTP, localhost, emulator, private-LAN, demo-login, or debug-OTP configuration.
9. Observe error rate, latency, database connections, rate-limit responses, and provider failures before widening release.

## Current blockers before deployment

- Fast2SMS delivery is implemented outside development. Account KYC, wallet funding, and DLT-approved sender/route activation must be confirmed with a real staging delivery before release.
- Index creation must be rehearsed on a disposable clean MongoDB database. The unique indexes on `users.phone`, `farm_profiles.userId`, and `refresh_tokens.tokenHash` fail to build if an existing database already holds duplicates; deduplicate before running them.
- Hosting accounts, regions, database plans, custom-domain ownership, DNS access, alert recipients, retention requirements, and a rollback operator are not selected.
- Android release signing and store credentials must be configured outside Git before publishing.
- The endpoint limiter is in-process. Multi-instance production needs provider edge limits or a shared rate-limit store for a global budget.

The backend is deployed to a self-managed server. See [ubuntu-vps.md](ubuntu-vps.md) for the authoritative process, firewall, TLS, and backup configuration. [managed-hosting.md](managed-hosting.md) remains comparison material for a managed platform.
