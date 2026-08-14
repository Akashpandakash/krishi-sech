# Build context is web/, not the repo root.
#   docker build --build-arg NEXT_PUBLIC_API_BASE_URL=https://api.krishisech.com \
#     -t krishi-sech-web web/
ARG NODE_VERSION=20-bookworm-slim

FROM node:${NODE_VERSION} AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# NEXT_PUBLIC_* values are inlined into the client bundle at build time, so the
# API origin is fixed per image and cannot be changed by the runtime
# environment. One image per environment; never pass a secret this way — the
# value ships to every browser.
ARG NEXT_PUBLIC_API_BASE_URL
RUN test -n "$NEXT_PUBLIC_API_BASE_URL" || { \
      echo "NEXT_PUBLIC_API_BASE_URL build arg is required — without it the panel would ship pointing at http://localhost:7001"; \
      exit 1; \
    }
ENV NEXT_PUBLIC_API_BASE_URL=$NEXT_PUBLIC_API_BASE_URL

COPY . .
RUN npm run build


FROM node:${NODE_VERSION} AS runtime
WORKDIR /app

ENV NODE_ENV=production \
    # Standalone binds to localhost unless told otherwise, which is unreachable
    # from outside the container.
    HOSTNAME=0.0.0.0 \
    # The API owns 7001; the panel takes 7002.
    PORT=7002

# Standalone traces the server bundle; static assets and public/ are not part
# of that trace and have to be copied alongside it.
COPY --from=build /app/public ./public
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static

USER node

EXPOSE 7002

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:'+(process.env.PORT||7002)+'/').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "server.js"]
