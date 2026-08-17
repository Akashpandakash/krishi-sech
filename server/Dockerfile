# Build context is server/, not the repo root.
#   docker build -t krishi-sech-api server/
#
# Node 20 LTS matches the runtime contract in docs/deployment/README.md and the
# engines field. Debian slim rather than Alpine: firebase-admin and the Google
# Cloud libraries pull prebuilt binaries that assume glibc.
ARG NODE_VERSION=20-bookworm-slim

FROM node:${NODE_VERSION} AS build
WORKDIR /app

# Dependencies install from the lockfile alone, so this layer survives every
# source edit.
COPY package.json package-lock.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# Reinstall without dev dependencies so the runtime image carries no compiler.
RUN npm ci --omit=dev


FROM node:${NODE_VERSION} AS runtime
WORKDIR /app

ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=7001

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY package.json ./

# The `node` user ships with the image (uid 1000). Nothing here is writable by
# it, which is what we want: the server writes to MongoDB, never to disk.
USER node

EXPOSE 7001

# Readiness, not liveness: an instance whose database is unreachable should not
# be admitted to a load balancer. Matches the deployment runbook.
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||7001)+'/api/ready').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# Index creation stays an explicit deploy step, exactly as it is outside Docker:
#   docker run --rm --env-file <file> krishi-sech-api node dist/database/ensure-indexes.js
CMD ["node", "dist/server.js"]
