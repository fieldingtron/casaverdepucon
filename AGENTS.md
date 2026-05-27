# Agents Guide — CVP Local WordPress Mirror

This document describes how AI agents (Claude Code or similar) should work with this repository.

## Project Summary

This repo is a local Docker-based mirror of `casaverdepucon.com`, a Chilean architecture firm's WordPress site hosted on DreamHost. The workflow is: pull remote DB/files → run locally on Docker → test → iterate.

No application code is written here. Work is operational: syncing, configuring, scripting, and testing the local mirror.

## Repo Map

| Path | What it is |
|------|-----------|
| `docker-compose.yml` | MySQL 8.0 + WordPress PHP 8.4 + WP-CLI PHP 8.4 |
| `.env` | Local config (git-ignored); see README for variables |
| `scripts/pull-db.sh` | Remote dump → local import + URL rewrite |
| `scripts/pull-files.sh` | rsync remote files to `site/` |
| `scripts/apply-local-overrides.sh` | Theme, plugin, nav, contact page patches post-import |
| `scripts/wp.sh` | WP-CLI wrapper (runs inside `wpcli` container) |
| `scripts/smoke-test.sh` | curl + WP-CLI health checks |
| `scripts/visual-smoke-test.sh` | Playwright bootstrap runner |
| `scripts/visual-smoke-test.js` | Playwright headless Chromium test (5 pages × 2 viewports) |
| `scripts/optimize-images-local.sh` | ImageMagick bulk resize of uploads/gallery |
| `site/` | WordPress root — synced from remote, git-ignored |
| `backups/` | SQL dump archives — git-ignored |
| `artifacts/visual-smoke/` | Playwright screenshots — git-ignored |

## Key Conventions

- **WP-CLI always runs in the container.** Use `./scripts/wp.sh <args>` — never call `wp` directly on the host.
- **URL rewriting is handled by `pull-db.sh`.** After import, all production URLs (`https://casaverdepucon.com`) are rewritten to `http://localhost:8083`.
- **`wp-config.php` is preserved locally.** `pull-files.sh` excludes it so Docker credentials are never overwritten by the remote copy.
- **`site/` is not committed.** It is large and continuously synced from the remote. Never `git add site/`.
- **Smush is swapped for EWWW.** The production site uses Smush (wp-smushit), but local testing uses EWWW Image Optimizer. `apply-local-overrides.sh` handles this swap automatically.
- **Theme is `cvp-twentyten`.** A child theme of Twenty Ten with responsive CSS overrides. Always activated as part of local overrides.

## Typical Agent Tasks

### Check if the local mirror is healthy
```bash
./scripts/smoke-test.sh
```

### Run visual regression screenshots
```bash
./scripts/visual-smoke-test.sh
# Screenshots land in artifacts/visual-smoke/
```

### Run a WP-CLI command
```bash
./scripts/wp.sh plugin list
./scripts/wp.sh option get home
./scripts/wp.sh theme list
```

### Refresh from production
```bash
./scripts/pull-db.sh    # database only
./scripts/pull-files.sh # files only (rsync)
./scripts/setup.sh      # first-time: both
```

### Check Docker container status
```bash
docker compose ps
docker compose logs wordpress --tail=50
docker compose logs db --tail=50
```

## What to Avoid

- Do not commit anything in `site/`, `backups/`, or `artifacts/`.
- Do not edit `site/wp-config.php` — it is managed by Docker and excluded from syncs.
- Do not run WP-CLI commands outside the container (`./scripts/wp.sh` wraps this correctly).
- Do not push to production — this repo exists purely for local development/testing.
- Do not delete `backups/` entries without confirming with the user — they may be the only copy of a database state.

## Environment Prerequisites

- Docker Desktop (or Docker Engine + Compose v2)
- SSH alias `cvp` configured in `~/.ssh/config` pointing to the DreamHost server
- ImageMagick (`brew install imagemagick`) — only needed for `optimize-images-local.sh`
- Node.js — only needed for `visual-smoke-test.sh` (Playwright auto-installs on first run)
