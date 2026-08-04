# Option A: managed hosting

The recommended RC1 implementation is Render Web Service plus Render Postgres. Railway can use the same commands and environment contract, with equally isolated staging and production services/databases.

## Service configuration

- Runtime: Node.js 20 LTS.
- Repository: protected release branch; passing CI required before auto-deploy.
- Build: `npm ci && npm run build`
- Pre-deploy migration: `npm run migrate:deploy`
- Start: `npm start`
- Health check: `/api/ready`
- Public port: use platform `PORT`; never expose PostgreSQL publicly.
- HTTPS: attach the custom domain and require its managed certificate before Flutter uses it.
- Auto-deploy: enable after CI only; keep staging automatic and production approval-controlled.

Create separate services and PostgreSQL instances for staging and production, colocated by region. Store variables in the provider secret store using the main runbook inventory. Set `TRUST_PROXY=true`; allow only exact approved HTTPS browser origins in `CORS_ALLOWED_ORIGINS`.

## Deployment checklist

1. Confirm commit SHA and passing test results.
2. Verify automated database backup and take a pre-release snapshot.
3. Confirm environment names and non-secret flags without displaying secret values.
4. Run the build; stop on install, Prisma generation, or TypeScript errors.
5. Run `npm run migrate:deploy` exactly once for the target database.
6. Start and require HTTP 200 from `/api/health` and `/api/ready`.
7. Confirm the custom domain serves HTTPS only.
8. Smoke-test authentication and verify request IDs, sanitized errors, CORS denial, and rate limits.
9. Observe logs, latency, memory, database connections, and errors through a soak window.
10. Promote Flutter configuration only after API stability.

## Rollback

1. Stop promotion and identify the last known-good deploy by commit SHA.
2. Roll back/redeploy that exact artifact or commit in the platform.
3. Require `/api/ready` before restoring traffic.
4. Do not improvise reverse Prisma migrations. Leave backward-compatible schema changes and ship a forward fix. For incompatible/destructive changes, enter maintenance, restore the verified pre-deploy snapshot to a new database, repoint the secret reference, and verify readiness before traffic.
5. Record request IDs, deploy IDs, and recovery checks without secrets or personal data.

For multiple application instances, configure provider-level path limits or a shared limiter store; the current application limiter is process-local.
