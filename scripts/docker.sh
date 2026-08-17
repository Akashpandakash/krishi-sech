#!/usr/bin/env bash
#
# Docker helper for the Krishi Sech stack (MongoDB + API + admin panel).
#
# Every command that starts or builds something validates the environment
# first, because the two most common failures — a missing server/.env and an
# unset NEXT_PUBLIC_API_BASE_URL — both produce a stack that comes up looking
# healthy and is wrong: no database credentials, or a panel hard-wired to
# the wrong API origin inside its client bundle.
#
# Values are never printed. Checks report on names and emptiness only.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ROOT_ENV="$ROOT_DIR/.env"
ROOT_ENV_EXAMPLE="$ROOT_DIR/.env.example"
SERVER_ENV="$ROOT_DIR/server/.env"
SERVER_ENV_EXAMPLE="$ROOT_DIR/server/.env.example"

if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; RED=$'\033[31m'; YELLOW=$'\033[33m'
  GREEN=$'\033[32m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
  BOLD=''; RED=''; YELLOW=''; GREEN=''; DIM=''; RESET=''
fi

ERRORS=0
WARNINGS=0

ok()   { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$1"; }
note() { printf '  %s·%s %s\n' "$DIM" "$RESET" "$1"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$1"; WARNINGS=$((WARNINGS + 1)); }
bad()  { printf '  %s✗%s %s\n' "$RED" "$RESET" "$1"; ERRORS=$((ERRORS + 1)); }
head_() { printf '\n%s%s%s\n' "$BOLD" "$1" "$RESET"; }
die()  { printf '\n%serror:%s %s\n' "$RED" "$RESET" "$1" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Usage: ./scripts/docker.sh <command> [args]

  check              Validate Docker, env files and required settings
  build [service]    Build images (api, web, or all)
  up                 Validate, build and start the stack in the background
  down [--volumes]   Stop the stack (--volumes also deletes the database)
  restart [service]  Restart a running service
  logs [service]     Follow logs
  ps                 Show service status
  indexes            Create MongoDB indexes (run after a schema change)
  create-admin ...   Create an admin account, e.g.
                     create-admin --email a@b.com --name "A B" --role owner
  help               This message

Compose settings live in ./.env (see .env.example).
Backend secrets live in ./server/.env and are never printed or copied.
USAGE
}

# ---------------------------------------------------------------- env reading

# Reads one key from a dotenv file WITHOUT sourcing it: a .env is data, and
# sourcing it would execute whatever it contains.
env_value() {
  local file=$1 key=$2 line
  [[ -f $file ]] || return 1
  line=$(grep -E "^[[:space:]]*(export[[:space:]]+)?${key}=" "$file" 2>/dev/null | tail -n1) || return 1
  [[ -n $line ]] || return 1
  line=${line#*=}
  line=${line%$'\r'}
  line="$(printf '%s' "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  line=${line#\"}; line=${line%\"}
  line=${line#\'}; line=${line%\'}
  printf '%s' "$line"
}

env_is_set() {
  local value
  value="$(env_value "$1" "$2" || true)"
  [[ -n $value ]]
}

env_equals() {
  local value
  value="$(env_value "$1" "$2" || true)"
  [[ "$value" == "$3" ]]
}

# True when the value still looks like the shipped placeholder.
env_is_placeholder() {
  local value
  value="$(env_value "$1" "$2" || true)"
  [[ $value == *replace-with* || $value == *change-me* || $value == *changeme* ]]
}

# ------------------------------------------------------------- docker probing

COMPOSE=()
DOCKER_OK=0

# Records problems rather than exiting, so `check` can report a broken Docker
# AND a broken .env in one pass instead of one per run.
check_docker() {
  local quiet=${1:-}
  [[ -n $quiet ]] || head_ "Docker"

  if ! command -v docker >/dev/null 2>&1; then
    bad "docker is not installed or not on PATH"
    return 0
  fi

  if ! docker info >/dev/null 2>&1; then
    bad "cannot reach the Docker daemon"
    printf '      %sthe daemon is stopped, or your user cannot use its socket:%s\n' "$DIM" "$RESET"
    printf '      %ssudo systemctl start docker%s\n' "$DIM" "$RESET"
    printf '      %ssudo usermod -aG docker "$USER"  (then log out and back in)%s\n' "$DIM" "$RESET"
    return 0
  fi
  [[ -n $quiet ]] || ok "daemon reachable"

  if docker compose version >/dev/null 2>&1; then
    COMPOSE=(docker compose)
  elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE=(docker-compose)
    warn "using the legacy docker-compose binary; the v2 plugin is preferred"
  else
    bad "Docker Compose is not available; install the 'docker compose' plugin"
    return 0
  fi
  [[ -n $quiet ]] || ok "compose available"
  DOCKER_OK=1
}

require_docker() {
  check_docker quiet
  [[ $DOCKER_OK -eq 1 ]] || die "Docker is not usable. Run ./scripts/docker.sh check for details."
}

# ------------------------------------------------------------- env validation

ensure_env_files() {
  head_ "Environment files"

  if [[ -f $ROOT_ENV ]]; then
    ok ".env present (compose settings)"
  elif [[ -f $ROOT_ENV_EXAMPLE ]]; then
    cp "$ROOT_ENV_EXAMPLE" "$ROOT_ENV"
    warn ".env was missing — created from .env.example. Review it."
  else
    bad ".env and .env.example are both missing"
  fi

  if [[ -f $SERVER_ENV ]]; then
    ok "server/.env present (backend secrets)"
  elif [[ -f $SERVER_ENV_EXAMPLE ]]; then
    cp "$SERVER_ENV_EXAMPLE" "$SERVER_ENV"
    warn "server/.env was missing — created from server/.env.example."
    warn "It ships placeholder secrets. Replace them before anything but local work."
  else
    bad "server/.env is missing and server/.env.example does not exist"
  fi
}

check_compose_settings() {
  head_ "Compose settings (.env)"
  [[ -f $ROOT_ENV ]] || return 0

  if env_is_set "$ROOT_ENV" NEXT_PUBLIC_API_BASE_URL; then
    ok "NEXT_PUBLIC_API_BASE_URL set"
    note "baked into the panel at build time — a change needs 'build web', not a restart"
  else
    bad "NEXT_PUBLIC_API_BASE_URL is empty; the panel image build will fail"
  fi

  local web_port cors api_url
  web_port="$(env_value "$ROOT_ENV" WEB_PORT || true)"
  web_port=${web_port:-7002}
  api_url="$(env_value "$ROOT_ENV" NEXT_PUBLIC_API_BASE_URL || true)"
  cors="$(env_value "$ROOT_ENV" CORS_ALLOWED_ORIGINS || true)"
  if [[ -z $cors ]]; then
    warn "CORS_ALLOWED_ORIGINS is empty; the panel's browser calls will be blocked"
  elif [[ $cors == *"*"* ]]; then
    bad "CORS_ALLOWED_ORIGINS contains a wildcard, which the API rejects in production"
  elif [[ $cors != *"localhost:${web_port}"* && $cors != *"://"*  ]]; then
    warn "CORS_ALLOWED_ORIGINS does not look like a URL origin list"
  else
    ok "CORS_ALLOWED_ORIGINS set"
  fi

  # A public API with localhost-only CORS is the signature of a half-finished
  # deploy: the panel is served from a real hostname, so that is the Origin the
  # API will be asked to allow, and every call fails preflight.
  if [[ -n $api_url && $api_url != *localhost* && $api_url != *127.0.0.1* ]]; then
    local origin public_origins=0
    local -a origins=()
    IFS=',' read -ra origins <<<"$cors"
    for origin in "${origins[@]:-}"; do
      origin="${origin//[[:space:]]/}"
      if [[ -n $origin && $origin != *localhost* && $origin != *127.0.0.1* ]]; then
        public_origins=$((public_origins + 1))
      fi
    done
    if [[ $public_origins -eq 0 ]]; then
      warn "the API is on a public host but CORS_ALLOWED_ORIGINS lists no public origin"
      printf "      %sit must be the PANEL's origin, e.g. https://stage-admin.krishisech.com%s\n" "$DIM" "$RESET"
    fi
    if [[ $api_url == http://* ]]; then
      warn "NEXT_PUBLIC_API_BASE_URL is http:// on a public host; tokens would cross the network in clear text"
    fi
  fi

}

# Classifies the effective database without ever printing it: a hosted URI
# carries a username and password.
check_database() {
  head_ "Database"

  local uri source profiles
  uri="$(env_value "$ROOT_ENV" MONGODB_URI || true)"
  source=".env"
  if [[ -z $uri ]]; then
    uri="$(env_value "$SERVER_ENV" MONGODB_URI || true)"
    source="server/.env"
  fi

  if [[ -z $uri ]]; then
    bad "MONGODB_URI is set in neither .env nor server/.env; the server refuses to start without it"
    return 0
  fi

  profiles="$(env_value "$ROOT_ENV" COMPOSE_PROFILES || true)"

  case $uri in
    *localhost* | *127.0.0.1*)
      bad "MONGODB_URI (from ${source}) points at localhost"
      printf '      %sinside a container that is the container itself, not your host%s\n' "$DIM" "$RESET"
      printf '      %suse mongodb://mongo:27017/... with COMPOSE_PROFILES=local-db, or a hosted URI%s\n' "$DIM" "$RESET"
      ;;
    mongodb+srv://*)
      ok "hosted database (mongodb+srv) from ${source}"
      if [[ $profiles == *local-db* ]]; then
        warn "COMPOSE_PROFILES=local-db also starts the bundled MongoDB, which nothing will use"
      fi
      ;;
    *://mongo:* | *@mongo:*)
      if [[ $profiles == *local-db* ]]; then
        ok "bundled MongoDB service, from ${source}"
      else
        bad "MONGODB_URI names the bundled 'mongo' service, but COMPOSE_PROFILES=local-db is not set"
        printf '      %sthe mongo container will not start and the API will not resolve that host%s\n' "$DIM" "$RESET"
      fi
      ;;
    mongodb://* )
      ok "external database from ${source}"
      ;;
    *)
      bad "MONGODB_URI (from ${source}) does not look like a MongoDB connection string"
      ;;
  esac
  # A case branch ending in a false test would otherwise return non-zero and
  # `set -e` would end the run mid-report.
  return 0
}

check_backend_env() {
  head_ "Backend environment (server/.env)"
  [[ -f $SERVER_ENV ]] || return 0

  local app_env
  app_env="$(env_value "$SERVER_ENV" APP_ENV || true)"
  app_env=${app_env:-development}
  note "APP_ENV=${app_env}"

  local secrets=(
    JWT_ACCESS_SECRET
    JWT_REFRESH_SECRET
    OTP_HASH_SECRET
    ADMIN_JWT_ACCESS_SECRET
    ADMIN_JWT_REFRESH_SECRET
  )

  local key placeholders=() missing=()
  for key in "${secrets[@]}"; do
    if ! env_is_set "$SERVER_ENV" "$key"; then
      missing+=("$key")
    elif env_is_placeholder "$SERVER_ENV" "$key"; then
      placeholders+=("$key")
    fi
  done

  # Outside production the server falls back to development defaults, so a gap
  # here is a warning; in production it refuses to boot, so it is an error.
  if [[ ${#missing[@]} -gt 0 ]]; then
    if [[ $app_env == production ]]; then
      bad "unset in production: ${missing[*]}"
    else
      warn "unset (development fallbacks will be used): ${missing[*]}"
    fi
  fi
  if [[ ${#placeholders[@]} -gt 0 ]]; then
    if [[ $app_env == production ]]; then
      bad "still the shipped placeholder: ${placeholders[*]}"
    else
      warn "still the shipped placeholder: ${placeholders[*]}"
    fi
  fi
  if [[ ${#missing[@]} -eq 0 && ${#placeholders[@]} -eq 0 ]]; then
    ok "token secrets set"
  fi

  if [[ $app_env == production ]]; then
    local flag
    for flag in LOGGING_ENABLED DEMO_LOGIN_ENABLED DEBUG_OTP_ENABLED; do
      if env_equals "$SERVER_ENV" "$flag" true; then
        bad "${flag}=true is refused in production"
      fi
    done
  fi

  if env_is_set "$SERVER_ENV" DATA_GOV_API_KEY; then
    ok "DATA_GOV_API_KEY set (live mandi prices)"
  else
    note "DATA_GOV_API_KEY unset — /api/mandi answers 503 and the app says prices are unavailable"
  fi
}

run_checks() {
  check_docker
  ensure_env_files
  check_compose_settings
  check_database
  check_backend_env

  printf '\n'
  if [[ $ERRORS -gt 0 ]]; then
    printf '%s%d error(s)%s, %d warning(s).\n' "$RED" "$ERRORS" "$RESET" "$WARNINGS"
    return 1
  fi
  if [[ $WARNINGS -gt 0 ]]; then
    printf '%sReady, with %d warning(s).%s\n' "$YELLOW" "$WARNINGS" "$RESET"
  else
    printf '%sReady.%s\n' "$GREEN" "$RESET"
  fi
  return 0
}

wait_for_api() {
  local port attempt
  port="$(env_value "$ROOT_ENV" API_PORT || true)"
  port=${port:-7001}
  printf '\nWaiting for the API to report ready'
  for attempt in $(seq 1 40); do
    if curl -sf -o /dev/null "http://127.0.0.1:${port}/api/ready" 2>/dev/null; then
      printf '\n'
      ok "API ready on http://localhost:${port}"
      return 0
    fi
    printf '.'
    sleep 2
  done
  printf '\n'
  warn "API did not report ready. Check: ./scripts/docker.sh logs api"
  return 0
}

main() {
  local command=${1:-help}
  [[ $# -gt 0 ]] && shift || true

  case $command in
    help | -h | --help)
      usage
      ;;

    check)
      run_checks
      ;;

    build)
      run_checks || die "fix the errors above first"
      "${COMPOSE[@]}" build "$@"
      ;;

    up)
      run_checks || die "fix the errors above first"
      "${COMPOSE[@]}" up -d --build "$@"
      wait_for_api
      local web_port
      web_port="$(env_value "$ROOT_ENV" WEB_PORT || true)"
      ok "Admin panel on http://localhost:${web_port:-7002}/admin"
      note "first run: ./scripts/docker.sh create-admin --email you@example.com --name 'Your Name' --role owner"
      ;;

    down)
      require_docker
      if [[ ${1:-} == --volumes ]]; then
        printf '%sThis deletes the mongo-data volume and every row in it.%s\n' "$YELLOW" "$RESET"
        read -r -p 'Type the word delete to continue: ' answer
        [[ $answer == delete ]] || die "cancelled"
        "${COMPOSE[@]}" down --volumes
      else
        "${COMPOSE[@]}" down
      fi
      ;;

    restart)
      require_docker
      "${COMPOSE[@]}" restart "$@"
      ;;

    logs)
      require_docker
      "${COMPOSE[@]}" logs -f "$@"
      ;;

    ps)
      require_docker
      "${COMPOSE[@]}" ps
      ;;

    indexes)
      require_docker
      "${COMPOSE[@]}" run --rm api node dist/database/ensure-indexes.js
      ;;

    create-admin)
      require_docker
      "${COMPOSE[@]}" run --rm api node dist/admin/scripts/create-admin.js "$@"
      ;;

    *)
      printf '%sUnknown command: %s%s\n\n' "$RED" "$command" "$RESET" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
