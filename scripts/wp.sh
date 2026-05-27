#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker compose -f "$PROJECT_DIR/docker-compose.yml" run --rm wpcli \
  wp "$@" --path=/var/www/html --allow-root
