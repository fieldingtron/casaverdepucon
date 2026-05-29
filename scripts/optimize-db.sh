#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

set -a
source "$PROJECT_DIR/.env"
set +a

DB_PREFIX="${WORDPRESS_TABLE_PREFIX:-wp_25apjn_}"
DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
DB_USER="${WORDPRESS_DB_USER:-wordpress}"
DB_PASS="${WORDPRESS_DB_PASSWORD:-wordpress}"

run_sql() {
  docker compose -f "$PROJECT_DIR/docker-compose.yml" exec -T db \
    mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" 2>/dev/null
}

echo "Truncating dead-plugin tables (Wordfence, MainWP, Smush)..."

run_sql <<SQL
-- Wordfence (plugin deleted locally)
TRUNCATE TABLE ${DB_PREFIX}wfAuditEvents;
TRUNCATE TABLE ${DB_PREFIX}wfBlockedIPLog;
TRUNCATE TABLE ${DB_PREFIX}wfBlocks7;
TRUNCATE TABLE ${DB_PREFIX}wfConfig;
TRUNCATE TABLE ${DB_PREFIX}wfCrawlers;
TRUNCATE TABLE ${DB_PREFIX}wfFileChanges;
TRUNCATE TABLE ${DB_PREFIX}wfFileMods;
TRUNCATE TABLE ${DB_PREFIX}wfHits;
TRUNCATE TABLE ${DB_PREFIX}wfHoover;
TRUNCATE TABLE ${DB_PREFIX}wfIssues;
TRUNCATE TABLE ${DB_PREFIX}wfKnownFileList;
TRUNCATE TABLE ${DB_PREFIX}wfLiveTrafficHuman;
TRUNCATE TABLE ${DB_PREFIX}wfLocs;
TRUNCATE TABLE ${DB_PREFIX}wfLogins;
TRUNCATE TABLE ${DB_PREFIX}wfNotifications;
TRUNCATE TABLE ${DB_PREFIX}wfPendingIssues;
TRUNCATE TABLE ${DB_PREFIX}wfReverseCache;
TRUNCATE TABLE ${DB_PREFIX}wfSNIPCache;
TRUNCATE TABLE ${DB_PREFIX}wfSecurityEvents;
TRUNCATE TABLE ${DB_PREFIX}wfStatus;
TRUNCATE TABLE ${DB_PREFIX}wfTrafficRates;
TRUNCATE TABLE ${DB_PREFIX}wfWafFailures;
TRUNCATE TABLE ${DB_PREFIX}wfls_2fa_secrets;
TRUNCATE TABLE ${DB_PREFIX}wfls_role_counts;
TRUNCATE TABLE ${DB_PREFIX}wfls_settings;

-- MainWP child (production management plugin, no local use)
TRUNCATE TABLE ${DB_PREFIX}mainwp_child_changes_logs;
TRUNCATE TABLE ${DB_PREFIX}mainwp_child_changes_meta;

-- Smush (plugin deleted locally)
TRUNCATE TABLE ${DB_PREFIX}smush_dir_images;

-- Action Scheduler logs (stale cron history, not needed locally)
TRUNCATE TABLE ${DB_PREFIX}actionscheduler_logs;

-- AIOSEO notifications (UI-only blobs, not needed locally)
TRUNCATE TABLE ${DB_PREFIX}aioseo_notifications;
SQL

echo "Optimizing all tables..."

# Build OPTIMIZE TABLE statement from current table list
TABLES=$(run_sql -e "SHOW TABLES;" | tail -n +2 | tr '\n' ',' | sed 's/,$//')
run_sql -e "OPTIMIZE TABLE ${TABLES};" | grep -v "^Table" | grep -v "OK$" || true

echo "Database optimization complete."
