# Render deployment configuration

`render.yaml` is the authoritative Render Blueprint. Committing it does not deploy anything. Importing or applying it in Render creates resources and must wait for deployment approval.

## Resources

| Environment | Web service | Custom domain | PostgreSQL | Region |
| --- | --- | --- | --- | --- |
| Staging | `krishi-sech-api-staging` (Starter) | `staging-api.krishisech.com` | `krishi-sech-db-staging` (Basic 256 MB, 15 GB) | Singapore |
| Production | `krishi-sech-api-production` (Starter) | `api.krishisech.com` | `krishi-sech-db-production` (Basic 1 GB, 15 GB) | Singapore |

Both databases use PostgreSQL 17, storage autoscaling, and an empty public IP allow list. Their internal connection strings are injected into their matching web services through `fromDatabase`; database credentials are never stored in Git. Staging and production share neither services, databases, nor secrets.

The backend uses Node 20, `npm ci && npm run build`, `npm run migrate:deploy`, and `npm start`. Render gates service health on `GET /api/ready`. Auto-deploy is initially off for both services. After the first staging deployment and CI integration, staging may be changed to `checksPass`; production should remain approval-controlled.

## Secret entry during Blueprint creation

Render generates independent values for these in each environment:

- `JWT_ACCESS_SECRET`
- `JWT_REFRESH_SECRET`
- `OTP_HASH_SECRET`

Render prompts for `OPENAI_API_KEY` because it is declared with `sync: false`. Enter the existing appropriate backend key directly in Render; do not paste it into source control, Flutter, documentation, deployment logs, or support messages.

Fast2SMS is selected outside development. Enter `FAST2SMS_API_KEY`, `FAST2SMS_SENDER_ID`, and `FAST2SMS_ROUTE` directly in Render when prompted. The API key, phone number, and OTP must never appear in source control or logs. Fast2SMS account activation, wallet balance, KYC, and DLT-approved sender/route configuration remain external deployment prerequisites.

## Non-secret service variables

The Blueprint explicitly sets `NODE_VERSION`, `NODE_ENV`, `APP_ENV`, `HOST`, timeout and logging flags, demo/debug flags, OpenAI model/enablement, weather provider, proxy trust, CORS, rate-limit controls, and OTP throttling controls. Render supplies `PORT`; do not override it.

Production browser CORS allows only `https://krishisech.com` and `https://www.krishisech.com`. Staging currently has no browser origin allowlist; native Flutter requests remain supported because they do not send browser CORS Origin headers. Add a staging web origin only if a staging website is created.

## Database initialization

1. Render creates each PostgreSQL instance before its dependent web service.
2. The internal `connectionString` becomes `DATABASE_URL` for only the matching service.
3. The paid web service runs `npm run migrate:deploy` as its pre-deploy command.
4. Prisma applies the baseline and later recommendation migrations.
5. `/api/ready` must return HTTP 200 before Render admits the instance.

Before the first deployment, rehearse the migration chain on a disposable clean PostgreSQL 17 database. If any existing database has tables created outside Prisma migrations, reconcile its migration history instead of applying the baseline blindly.

## DNS records

Create these records only after Render displays each service's actual `onrender.com` hostname:

| Type | Host/name | Target/value | TTL |
| --- | --- | --- | --- |
| CNAME | `api` | Render hostname for `krishi-sech-api-production` | 300 seconds during verification |
| CNAME | `staging-api` | Render hostname for `krishi-sech-api-staging` | 300 seconds during verification |

Do not point either API hostname at the other environment. Remove conflicting `A`, `AAAA`, or CNAME records for these two names. Render currently uses IPv4 and warns that conflicting `AAAA` records can prevent custom-domain validation. If the zone has CAA restrictions, authorize both `letsencrypt.org` and `pki.goog`. Render provisions and renews TLS after domain verification and redirects HTTP to HTTPS.

The main `krishisech.com` record is not managed by this backend Blueprint; it must point to the separate website host. It is included only as the production CORS origin.

## First-deployment checklist (not executed)

1. Confirm the Git repository and default production branch in Render.
2. Review the Blueprint resource names, Singapore region, plans, and projected cost.
3. Rehearse all Prisma migrations on disposable PostgreSQL 17.
4. Create a Render Blueprint from `render.yaml`; enter secrets only in Render's prompt.
5. Keep both auto-deploy settings off.
6. Deploy staging first and wait for `/api/health` and `/api/ready` to return 200.
7. Add and verify `staging-api.krishisech.com`, then run authenticated smoke tests.
8. Create a manual staging logical backup and prove restoration.
9. Approve production separately, verify `api.krishisech.com`, and run release smoke tests.
10. Enable alerting and define the rollback operator before distributing Flutter production builds.

## Rollback

Roll back the web service to the previous successful Render artifact and wait for `/api/ready`. For backward-compatible schema changes, retain the schema and issue a forward correction. For an incompatible migration, stop writes and use Render point-in-time recovery to create a separate recovery database; validate it before replacing `DATABASE_URL`. Never edit the generated database URL into source control.
