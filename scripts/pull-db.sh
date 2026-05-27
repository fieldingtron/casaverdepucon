#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

set -a
source "$PROJECT_DIR/.env"
set +a

STAMP="$(date +%Y%m%d-%H%M%S)"
REMOTE_DUMP="/tmp/cvp-${STAMP}.sql.gz"
LOCAL_DUMP="$PROJECT_DIR/backups/cvp-${STAMP}.sql.gz"

mkdir -p "$PROJECT_DIR/backups"

echo "Creating remote database dump..."
ssh "${CVP_SSH_HOST:-cvp}" "cd '${CVP_REMOTE_PATH:-/home/dh_g8vmkg/casaverdepucon.com}' && wp db export - --allow-root | gzip -1 > '$REMOTE_DUMP'"

echo "Downloading database dump..."
scp "${CVP_SSH_HOST:-cvp}:$REMOTE_DUMP" "$LOCAL_DUMP"

echo "Removing temporary remote dump..."
ssh "${CVP_SSH_HOST:-cvp}" "rm -f '$REMOTE_DUMP'"

echo "Starting Docker services..."
docker compose -f "$PROJECT_DIR/docker-compose.yml" up -d

echo "Waiting for WordPress database..."
until docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db mysqladmin ping -h 127.0.0.1 -u"$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" --silent >/dev/null 2>&1; do
  sleep 2
done

echo "Resetting and importing local database..."
"$PROJECT_DIR/scripts/wp.sh" db reset --yes >/dev/null
gunzip -c "$LOCAL_DUMP" | docker compose -f "$PROJECT_DIR/docker-compose.yml" run --rm -T wpcli \
  wp db import - --path=/var/www/html --allow-root

echo "Rewriting URLs for local mirror..."
"$PROJECT_DIR/scripts/wp.sh" search-replace "${CVP_REMOTE_URL:-https://casaverdepucon.com}" "${CVP_LOCAL_URL:-http://localhost:8083}" --all-tables --precise --skip-columns=guid
"$PROJECT_DIR/scripts/wp.sh" option update home "${CVP_LOCAL_URL:-http://localhost:8083}" >/dev/null
"$PROJECT_DIR/scripts/wp.sh" option update siteurl "${CVP_LOCAL_URL:-http://localhost:8083}" >/dev/null
"$PROJECT_DIR/scripts/apply-local-overrides.sh"

echo "Imported $LOCAL_DUMP"
