#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

set -a
source "$PROJECT_DIR/.env"
set +a

URL="${CVP_LOCAL_URL:-http://localhost:8083}"

curl -fsS "$URL" >/dev/null
curl -fsS "$URL/wp-login.php" >/dev/null
"$PROJECT_DIR/scripts/wp.sh" core is-installed >/dev/null
"$PROJECT_DIR/scripts/wp.sh" option get home
"$PROJECT_DIR/scripts/wp.sh" option get siteurl

echo "Smoke test passed for $URL"
