#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

set -a
source "$PROJECT_DIR/.env"
set +a

rsync -az --info=progress2 \
  --exclude='.git/' \
  --exclude='wp-config.php' \
  --exclude='wp-content/plugins/query-monitor/' \
  --exclude='wp-content/plugins/contact-form-plugin/' \
  --exclude='wp-content/plugins/si-contact-form/' \
  --exclude='wp-content/cache/' \
  --exclude='wp-content/upgrade/' \
  --exclude='wp-content/wflogs/' \
  --exclude='wp-content/uploads/aioseo-logs/' \
  --exclude='wp-content/uploads/sucuri/' \
  --exclude='*.sql' \
  --exclude='*.sql.gz' \
  --exclude='*.tar' \
  --exclude='*.tar.gz' \
  --exclude='*.zip' \
  "$PROJECT_DIR/site/" \
  "${CVP_SSH_HOST:-cvp}:${CVP_REMOTE_PATH:-/home/dh_g8vmkg/casaverdepucon.com}/"
