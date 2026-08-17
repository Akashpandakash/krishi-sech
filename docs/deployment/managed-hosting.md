# Option A: managed hosting

The recommended RC1 implementation is Render Web Service plus a managed MongoDB cluster (MongoDB Atlas). Railway can use the same commands and environment contract, with equally isolated staging and production services/databases.

## Service configuration

- Runtime: Node.js 20 LTS.
- Repository: protected release branch; passing CI required before auto-deploy.
- Repository root directory for the service: `server/`
- Build: `npm ci && npm run build`
- Pre-deploy index setup: `npm run db:indexes`
- Start: `npm start`
- Health check: `/api/ready`
- Public port: use platform `PORT`; never expose MongoDB publicly. Restrict cluster access to the platform's outbound addresses.
- HTTPS: attach the custom domain and require its managed certificate before Flutter uses it.
- Auto-deploy: enable after CI only; keep staging automatic and production approval-controlled.

Create separate services and MongoDB clusters (or at minimum separate databases with separate users) for staging and production, colocated by region. Store variables in the provider secret store using the main runbook inventory. Set `TRUST_PROXY=true`; allow only exact approved HTTPS browser origins in `CORS_ALLOWED_ORIGINS`.

## Deployment checklist

1. Confirm commit SHA and passing test results.
2. Verify automated database backup and take a pre-release snapshot.
3. Confirm environment names and non-secret flags without displaying secret values.
4. Run the build; stop on install or TypeScript errors.
5. Run `npm run db:indexes` for the target database.
6. Start and require HTTP 200 from `/api/health` and `/api/ready`.
7. Confirm the custom domain serves HTTPS only.
8. Smoke-test authentication and verify request IDs, sanitized errors, CORS denial, and rate limits.
9. Observe logs, latency, memory, database connections, and errors through a soak window.
10. Promote Flutter configuration only after API stability.

## Rollback

1. Stop promotion and identify the last known-good deploy by commit SHA.
2. Roll back/redeploy that exact artifact or commit in the platform.
3. Require `/api/ready` before restoring traffic.
4. Do not improvise reverse data migrations. Leave backward-compatible document-shape changes and ship a forward fix. For incompatible/destructive changes, enter maintenance, restore the verified pre-deploy snapshot to a new database, repoint `MONGODB_URI`, and verify readiness before traffic.
5. Record request IDs, deploy IDs, and recovery checks without secrets or personal data.

For multiple application instances, configure provider-level path limits or a shared limiter store; the current application limiter is process-local.
