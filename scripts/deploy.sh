#!/usr/bin/env bash
#
# Host-level deployment for the Krishi Sech VPS. Containers are ./scripts/docker.sh;
# this script handles what lives outside them — currently the Nginx reverse proxy.
#
# Domains are read from ./.env so there is one source of truth: the panel's
# origin has to match CORS_ALLOWED_ORIGINS exactly, and deriving both from the
# same file is what keeps them from drifting apart.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ROOT_ENV="$ROOT_DIR/.env"
CONF_SOURCE="$ROOT_DIR/docs/deployment/nginx"
# Overridable so the install path can be exercised against a scratch directory
# instead of a live web server.
SITES_AVAILABLE=${NGINX_SITES_AVAILABLE:-/etc/nginx/sites-available}
SITES_ENABLED=${NGINX_SITES_ENABLED:-/etc/nginx/sites-enabled}

# The placeholder hostnames inside the committed .conf files.
API_PLACEHOLDER=stage-api.krishisech.com
ADMIN_PLACEHOLDER=stage-admin.krishisech.com

if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; RED=$'\033[31m'; YELLOW=$'\033[33m'
  GREEN=$'\033[32m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
  BOLD=''; RED=''; YELLOW=''; GREEN=''; DIM=''; RESET=''
fi

# Staging directory for rendered configs. Global with an EXIT trap rather than
# a function-local RETURN trap: a RETURN trap fires again as each outer
# function returns, where the local no longer exists and `set -u` aborts.
STAGED=''
cleanup() { [[ -n ${STAGED:-} ]] && rm -rf "$STAGED"; return 0; }
trap cleanup EXIT

ok()    { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$1"; }
note()  { printf '  %s·%s %s\n' "$DIM" "$RESET" "$1"; }
warn()  { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$1"; }
step()  { printf '\n%s%s%s\n' "$BOLD" "$1" "$RESET"; }
die()   { printf '\n%serror:%s %s\n' "$RED" "$RESET" "$1" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Usage: ./scripts/deploy.sh <command> [options]

  nginx [options]    Install the reverse-proxy config and reload Nginx
  tls                Obtain certificates with certbot for both domains
  help               This message

Options for `nginx`:
  --api-domain <host>     Override the API hostname   (default: from .env)
  --admin-domain <host>   Override the panel hostname (default: from .env)
  --keep-default          Do not remove Nginx's packaged default site
  --dry-run               Render and report, change nothing

The API domain comes from NEXT_PUBLIC_API_BASE_URL and the panel domain from
the first non-localhost entry of CORS_ALLOWED_ORIGINS, both in ./.env.
USAGE
}

# ------------------------------------------------------------------ helpers

SUDO=''
require_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    SUDO=''
  elif command -v sudo >/dev/null 2>&1; then
    SUDO='sudo'
    note "not root; privileged steps will use sudo"
  else
    die "run as root, or install sudo."
  fi
}

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

# https://host:port/path -> host
url_host() {
  local url=$1
  url=${url#*://}
  url=${url%%/*}
  url=${url%%:*}
  printf '%s' "$url"
}

valid_hostname() {
  [[ $1 =~ ^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$ && $1 == *.* ]]
}

# ------------------------------------------------------------- nginx command

cmd_nginx() {
  local api_domain='' admin_domain='' keep_default=0 dry_run=0

  while [[ $# -gt 0 ]]; do
    case $1 in
      --api-domain)   api_domain=${2:-}; shift 2 ;;
      --admin-domain) admin_domain=${2:-}; shift 2 ;;
      --keep-default) keep_default=1; shift ;;
      --dry-run)      dry_run=1; shift ;;
      *) die "unknown option: $1" ;;
    esac
  done

  step "Domains"
  [[ -f $ROOT_ENV ]] || die ".env not found. Run ./scripts/docker.sh check first."

  if [[ -z $api_domain ]]; then
    api_domain="$(url_host "$(env_value "$ROOT_ENV" NEXT_PUBLIC_API_BASE_URL || true)")"
  fi
  if [[ -z $admin_domain ]]; then
    local cors origin
    cors="$(env_value "$ROOT_ENV" CORS_ALLOWED_ORIGINS || true)"
    local -a origins=()
    IFS=',' read -ra origins <<<"$cors"
    for origin in "${origins[@]:-}"; do
      origin="${origin//[[:space:]]/}"
      [[ -z $origin ]] && continue
      local host; host="$(url_host "$origin")"
      if [[ -n $host && $host != localhost && $host != 127.0.0.1 ]]; then
        admin_domain=$host
        break
      fi
    done
  fi

  valid_hostname "$api_domain" ||
    die "could not read an API hostname from .env (NEXT_PUBLIC_API_BASE_URL=${api_domain:-<empty>}). Pass --api-domain."
  ok "API    ${api_domain}"

  if ! valid_hostname "$admin_domain"; then
    die "no public panel hostname in CORS_ALLOWED_ORIGINS. Set it in .env (it must
       match the panel's origin exactly), or pass --admin-domain."
  fi
  ok "panel  ${admin_domain}"

  step "Nginx"
  command -v nginx >/dev/null 2>&1 ||
    die "nginx is not installed. Install it first:  sudo apt update && sudo apt install nginx"
  ok "$(nginx -v 2>&1)"
  [[ -d $CONF_SOURCE ]] || die "config templates missing: $CONF_SOURCE"

  # Render the templates with the real hostnames.
  STAGED="$(mktemp -d)"
  local staged=$STAGED

  local api_conf="${api_domain}.conf"
  local admin_conf="${admin_domain}.conf"
  sed -e "s/${API_PLACEHOLDER}/${api_domain}/g" \
      "$CONF_SOURCE/${API_PLACEHOLDER}.conf" > "$staged/$api_conf"
  sed -e "s/${ADMIN_PLACEHOLDER}/${admin_domain}/g" \
      "$CONF_SOURCE/${ADMIN_PLACEHOLDER}.conf" > "$staged/$admin_conf"
  cp "$CONF_SOURCE/00-default-server.conf" "$staged/00-default-server.conf"
  ok "rendered 3 site files"

  step "Upstreams"
  local port
  for port in 7001 7002; do
    if curl -sf -o /dev/null --max-time 3 "http://127.0.0.1:${port}/" 2>/dev/null ||
       curl -s -o /dev/null --max-time 3 "http://127.0.0.1:${port}/api/health" 2>/dev/null; then
      ok "127.0.0.1:${port} responding"
    else
      warn "nothing answering on 127.0.0.1:${port} — start the stack: ./scripts/docker.sh up"
    fi
  done

  if [[ $dry_run -eq 1 ]]; then
    step "Dry run"
    note "would install into ${SITES_AVAILABLE} and link into ${SITES_ENABLED}:"
    printf '      %s\n' "$api_conf" "$admin_conf" "00-default-server.conf"
    [[ $keep_default -eq 0 ]] && note "would remove ${SITES_ENABLED}/default"
    note "would run: nginx -t && systemctl reload nginx"
    printf '\n%sRendered API server block:%s\n' "$DIM" "$RESET"
    grep -vE '^\s*#' "$staged/$api_conf" |
      grep -E 'server_name|proxy_pass|listen|client_max_body_size' |
      sed 's/^ *//; s/^/      /'
    return 0
  fi

  require_root
  step "Install"

  # Anything already there is backed up, so a bad run can be undone by hand.
  local stamp; stamp="$(date +%Y%m%d%H%M%S)"
  local -a installed=()
  local file
  for file in "$api_conf" "$admin_conf" 00-default-server.conf; do
    if [[ -f "$SITES_AVAILABLE/$file" ]]; then
      $SUDO cp -a "$SITES_AVAILABLE/$file" "$SITES_AVAILABLE/${file}.bak.${stamp}"
      note "backed up ${file} -> ${file}.bak.${stamp}"
    fi
    $SUDO install -m 0644 "$staged/$file" "$SITES_AVAILABLE/$file"
    $SUDO ln -sfn "$SITES_AVAILABLE/$file" "$SITES_ENABLED/$file"
    installed+=("$file")
    ok "installed and enabled ${file}"
  done

  if [[ $keep_default -eq 0 && -e "$SITES_ENABLED/default" ]]; then
    $SUDO rm -f "$SITES_ENABLED/default"
    ok "removed the packaged default site (00-default-server.conf replaces it)"
  fi

  step "Validate"
  if ! $SUDO nginx -t; then
    printf '\n'
    warn "configuration rejected — rolling back, Nginx keeps serving what it has"
    for file in "${installed[@]}"; do
      $SUDO rm -f "$SITES_ENABLED/$file"
      if [[ -f "$SITES_AVAILABLE/${file}.bak.${stamp}" ]]; then
        $SUDO mv "$SITES_AVAILABLE/${file}.bak.${stamp}" "$SITES_AVAILABLE/$file"
        $SUDO ln -sfn "$SITES_AVAILABLE/$file" "$SITES_ENABLED/$file"
      else
        $SUDO rm -f "$SITES_AVAILABLE/$file"
      fi
    done
    die "nothing was changed. Fix the reported line and re-run."
  fi
  ok "syntax valid"

  $SUDO systemctl reload nginx
  ok "Nginx reloaded"

  step "Next"
  note "HTTP only so far — certbot adds TLS and the redirect:"
  printf '      ./scripts/deploy.sh tls\n'
  printf '      %s(or: sudo certbot --nginx -d %s -d %s)%s\n' \
    "$DIM" "$api_domain" "$admin_domain" "$RESET"
  note "the panel bundle has the API URL compiled in; if you changed it:"
  printf '      ./scripts/docker.sh build web && ./scripts/docker.sh up\n'
}

# --------------------------------------------------------------- tls command

cmd_tls() {
  local api_domain admin_domain
  api_domain="$(url_host "$(env_value "$ROOT_ENV" NEXT_PUBLIC_API_BASE_URL || true)")"
  admin_domain=''
  local cors origin host
  cors="$(env_value "$ROOT_ENV" CORS_ALLOWED_ORIGINS || true)"
  local -a origins=()
  IFS=',' read -ra origins <<<"$cors"
  for origin in "${origins[@]:-}"; do
    origin="${origin//[[:space:]]/}"
    [[ -z $origin ]] && continue
    host="$(url_host "$origin")"
    if [[ -n $host && $host != localhost && $host != 127.0.0.1 ]]; then
      admin_domain=$host
      break
    fi
  done

  valid_hostname "$api_domain" || die "no API hostname in .env"
  command -v certbot >/dev/null 2>&1 ||
    die "certbot is not installed:  sudo apt install certbot python3-certbot-nginx"
  require_root

  step "Certificates"
  note "DNS for these names must already point at this server"
  local -a args=(--nginx -d "$api_domain")
  if valid_hostname "$admin_domain"; then
    args+=(-d "$admin_domain")
    ok "requesting ${api_domain} and ${admin_domain}"
  else
    warn "no panel hostname found; requesting ${api_domain} only"
  fi

  $SUDO certbot "${args[@]}"
  ok "certificates issued; certbot rewrote the site files with the TLS block"
  note "verify renewal:  sudo certbot renew --dry-run"
}

main() {
  local command=${1:-help}
  [[ $# -gt 0 ]] && shift || true
  case $command in
    help | -h | --help) usage ;;
    nginx) cmd_nginx "$@" ;;
    tls)   cmd_tls "$@" ;;
    *)
      printf '%sUnknown command: %s%s\n\n' "$RED" "$command" "$RESET" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
