# Option B: Ubuntu VPS

Use Ubuntu 24.04 LTS with Nginx, MongoDB, Node 24 LTS, and systemd. This option requires a named operator for patching, monitoring, backup restoration, and incident response.

## Network and filesystem layout

- Permit inbound TCP 22 only from approved administrator IPs where possible, plus 80 and 443 publicly.
- Do not expose application port 3000 or MongoDB 27017 through UFW/security groups.
- Bind Node to `127.0.0.1:3000`; bind local MongoDB to loopback and require authentication.
- Store immutable releases under `/srv/krishi-sech/releases/<commit>` and point `/srv/krishi-sech/current` at the active release.
- Store production environment values in a root-owned `0600` file outside the repository.

## Commands and process supervision

- Node: pin Node 24 LTS from a supported package source. Node 20 cannot build this project — see the runtime contract in `README.md`.
- Build (from `server/`): `npm ci && npm run build`
- Create indexes: `npm run db:indexes`
- systemd start command: `/usr/bin/node /srv/krishi-sech/current/dist/server.js`
- Service identity: non-login `krishi-sech` user without sudo.
- Health: `GET /api/health`; readiness: `GET /api/ready`.

The systemd unit must use `WorkingDirectory=/srv/krishi-sech/current`, load the external environment file, restart on failure with a bounded delay, set `NoNewPrivileges=true`, and grant writes only where required. Use `After=network-online.target mongod.service` for local MongoDB. Set `TRUST_PROXY=true` because exactly one trusted Nginx proxy fronts Express.

## Nginx and TLS

Terminate TLS for `api.krishisech.com`, proxy to `http://127.0.0.1:3000`, preserve `Host`, and replace trusted `X-Forwarded-For`, `X-Forwarded-Proto`, and `X-Request-ID` headers. Use timeouts compatible with the backend and disease-image limits. Reject unknown Host headers in the default server.

Use Certbot’s Nginx integration for a Let’s Encrypt certificate and test automatic renewal with a dry run. Redirect HTTP to HTTPS only after certificate issuance.

## Logs, firewall, and backups

- UFW defaults to deny incoming; only the ports above are allowed. Mirror these rules in provider security groups.
- Send application logs to journald. Set explicit size/retention limits and alert on repeated restarts, readiness failures, HTTP 5xx, and disk pressure.
- Keep Ubuntu’s Nginx `logrotate` policy enabled; rotate daily, compress, retain for an agreed period, and verify rotation.
- Run daily encrypted `mongodump` backups with a least-privileged backup identity, transfer them off-server, and apply agreed daily/monthly retention. Take a snapshot before every release.
- Perform scheduled isolated restore drills; a backup is not accepted until restore and application readiness succeed.

## Deployment checklist

1. Patch Ubuntu and confirm disk, memory, clock, firewall, and backup state.
2. Stage the reviewed commit in a new immutable release directory.
3. From `server/`, run `npm ci`, `npm test`, and `npm run build` as the service user.
4. Snapshot MongoDB and run `npm run db:indexes`.
5. Atomically update `current` and restart systemd.
6. Verify systemd locally, then health/readiness through public HTTPS.
7. Verify TLS renewal, request IDs, sanitized errors, CORS, limits, and authenticated paths.
8. Monitor resources, logs, database connections, latency, and errors through the soak window.

## Rollback

1. Point `current` to the previous release and restart.
2. Require local and public readiness before reopening traffic.
3. Leave backward-compatible document-shape changes and ship a forward fix. For an incompatible data migration, stop writes, restore the pre-deploy snapshot into a new database, update the external `MONGODB_URI`, restart, and verify readiness.
4. Preserve release/journal metadata for investigation, excluding secrets and personal data.

PM2 is not required; systemd is preferred because it starts at boot, integrates with journald, and minimizes operational components.
