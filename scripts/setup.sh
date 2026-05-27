#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

docker compose -f "$PROJECT_DIR/docker-compose.yml" up -d
"$PROJECT_DIR/scripts/pull-db.sh"

echo ""
echo "CVP local mirror is available at $(grep '^CVP_LOCAL_URL=' "$PROJECT_DIR/.env" | cut -d= -f2-)"
