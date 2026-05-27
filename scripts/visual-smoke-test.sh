#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAYWRIGHT_DIR="${PLAYWRIGHT_DIR:-/private/tmp/cvp-pw}"

mkdir -p "$PLAYWRIGHT_DIR"

if [[ ! -f "$PLAYWRIGHT_DIR/package.json" ]]; then
  (cd "$PLAYWRIGHT_DIR" && npm init -y >/dev/null)
fi

if [[ ! -d "$PLAYWRIGHT_DIR/node_modules/playwright" ]]; then
  (cd "$PLAYWRIGHT_DIR" && npm install playwright >/dev/null)
fi

(cd "$PLAYWRIGHT_DIR" && npx playwright install chromium >/dev/null)

NODE_PATH="$PLAYWRIGHT_DIR/node_modules" node "$ROOT_DIR/scripts/visual-smoke-test.js"
