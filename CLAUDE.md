# CLAUDE.md — CVP Local WordPress Mirror

Instructions for Claude Code working in this repository.

## What This Repo Is

A local Docker mirror of `casaverdepucon.com` (Chilean architecture firm, DreamHost hosting). No application code is developed here — the work is operational: syncing from production, running locally, scripting, and testing.

## Running Commands

### Docker
```bash
docker compose up -d          # start stack
docker compose down           # stop stack
docker compose ps             # check container status
docker compose logs wordpress --tail=50
```

### WP-CLI — always via the wrapper
```bash
./scripts/wp.sh <command>     # runs inside the wpcli container
```
Never call `wp` directly on the host machine.

### Sync from production
```bash
./scripts/pull-db.sh          # fresh DB import (remote dump → local → URL rewrite)
./scripts/pull-files.sh       # rsync files from remote
```

### Tests
```bash
./scripts/smoke-test.sh             # curl + WP-CLI health check
./scripts/visual-smoke-test.sh      # Playwright screenshots (5 pages × 2 viewports)
```

## Important Rules

1. **Never commit `site/`, `backups/`, or `artifacts/`** — all are git-ignored and can be large.
2. **Never overwrite `site/wp-config.php`** — it holds Docker DB credentials and is excluded from `pull-files.sh`.
3. **Do not push changes to production** — this is a read-only local mirror for development/testing only.
4. **Do not run WP-CLI outside the container** — always use `./scripts/wp.sh`.
5. **URL rewriting is automatic** — `pull-db.sh` rewrites `https://casaverdepucon.com` → `http://localhost:8083` and calls `apply-local-overrides.sh`.

## Local Overrides Applied After Every DB Import

`scripts/apply-local-overrides.sh` runs automatically at the end of `pull-db.sh` and does:
- Activates `cvp-twentyten` child theme (Twenty Ten parent)
- Deactivates/deletes Smush; installs and activates EWWW Image Optimizer
- Activates the standard plugin set (akismet, aioseo, ml-slider, nextgen-gallery, sucuri, updraftplus, wordfence, etc.)
- Rebuilds Primary nav menu from published pages (excludes page 127; renames page 21 to "Inicio")
- Patches contact page (post ID 52) with local contact text
- Flushes rewrite rules

## Environment

All config is in `.env` (git-ignored). The stack works with defaults baked into `docker-compose.yml` even without `.env`.

Key values:
- Local URL: `http://localhost:8083`
- SSH alias: `cvp` (must be configured in `~/.ssh/config`)
- Remote path: `/home/dh_g8vmkg/casaverdepucon.com`
- DB credentials: `wordpress` / `wordpress` (local only, no security concern)

## Typical Workflow for a Fresh Environment

```bash
# 1. Ensure Docker Desktop is running
# 2. Ensure SSH alias 'cvp' works: ssh cvp 'echo ok'
# 3. Run setup
./scripts/setup.sh

# 4. Verify
./scripts/smoke-test.sh

# 5. Optional: visual check
./scripts/visual-smoke-test.sh
```

## File Conventions

- Shell scripts use `set -euo pipefail` and derive `PROJECT_DIR` from `${BASH_SOURCE[0]}`.
- Scripts source `.env` with `set -a / source / set +a` to export all variables.
- WP-CLI commands inside scripts always pass `--path=/var/www/html --allow-root`.
