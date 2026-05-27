#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

set -a
source "$PROJECT_DIR/.env"
set +a

rsync -az --info=progress2 \
  --exclude='.git/' \
  --exclude='wp-config.php' \
  --exclude='wp-content/plugins/contact-form-plugin/' \
  --exclude='wp-content/plugins/si-contact-form/' \
  --exclude='*.sql' \
  --exclude='*.sql.gz' \
  --exclude='*.tar' \
  --exclude='*.tar.gz' \
  --exclude='*.zip' \
  "${CVP_SSH_HOST:-cvp}:${CVP_REMOTE_PATH:-/home/dh_g8vmkg/casaverdepucon.com}/" \
  "$PROJECT_DIR/site/"
