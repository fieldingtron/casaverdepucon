# CVP Local WordPress Mirror

Local mirror of [casaverdepucon.com](https://casaverdepucon.com) — a Chilean architecture firm — pulled from SSH alias `cvp` (DreamHost hosting at `/home/dh_g8vmkg/casaverdepucon.com`).

## Stack

| Service   | Image                     | Role                          |
|-----------|---------------------------|-------------------------------|
| db        | mysql:8.0                 | MySQL database                |
| wordpress | wordpress:php8.4-apache   | Apache + PHP 8.4 web server   |
| wpcli     | wordpress:cli-php8.4      | WP-CLI command runner         |

Local URL: **http://localhost:8083** (configured via `WP_HTTP_PORT` in `.env`)

## Quick Start

```bash
# First-time setup (starts Docker + pulls remote DB)
./scripts/setup.sh

# Or just start containers if site/ and DB are already present
docker compose up -d
```

## Pull Fresh Database

```bash
./scripts/pull-db.sh
```

Workflow: remote WP-CLI dump → gzip → SCP to `backups/` → import into local MySQL → URL rewrite (`https://casaverdepucon.com` → `http://localhost:8083`) → apply local overrides.

Local overrides (`scripts/apply-local-overrides.sh`) include:
- Activates the `cvp-twentyten` child theme (Twenty Ten parent, custom responsive CSS)
- Replaces Smush with **EWWW Image Optimizer**
- Rebuilds the Primary nav menu from published pages (excludes page 127)
- Patches the contact page (post 52) with local contact details
- Flushes rewrite rules

## Pull Fresh Files

```bash
./scripts/pull-files.sh
```

rsync from remote, excluding `wp-config.php` (preserved locally) and archive files.

## WP-CLI

All WP-CLI commands run inside the `wpcli` Docker container:

```bash
./scripts/wp.sh option get home
./scripts/wp.sh plugin list
./scripts/wp.sh theme list
```

## Test

CLI smoke test (curl + WP-CLI core check):

```bash
./scripts/smoke-test.sh
```

Visual/browser smoke test (Playwright, headless Chromium):

```bash
./scripts/visual-smoke-test.sh
```

Pages tested: `home`, `contact` (`/contacto/`), `gallery` (`/fotos/`), `project` (`/casa-azocar/`), `login`.  
Viewports tested: mobile (390×844) and desktop (1366×900).  
Screenshots saved to `artifacts/visual-smoke/`.  
Checks: HTTP 2xx, no horizontal overflow, no broken images, no JS console errors.

## Optional Local Image Optimization

Requires ImageMagick (`brew install imagemagick`). Operates on `site/wp-content/uploads/` and `site/wp-content/gallery/`. Skips WP-generated thumbnails (files matching `*-WxH.*`).

```bash
# Dry run — preview what would be resized
./scripts/optimize-images-local.sh --dry-run

# Apply resizing (default: max width 2000, JPEG quality 88)
./scripts/optimize-images-local.sh

# Override defaults
MAX_WIDTH=1800 QUALITY=85 ./scripts/optimize-images-local.sh
```

## Environment Variables

All variables live in `.env` (git-ignored). Defaults are baked into `docker-compose.yml` so the stack works without a `.env` file.

| Variable              | Default                                    | Purpose                        |
|-----------------------|--------------------------------------------|--------------------------------|
| `WP_HTTP_PORT`        | `8083`                                     | Host port mapped to WordPress  |
| `WP_HOME`             | `http://localhost:8083`                    | WordPress home URL             |
| `WP_SITEURL`          | `http://localhost:8083`                    | WordPress site URL             |
| `WORDPRESS_DB_*`      | `wordpress` / `wordpress`                  | DB name, user, password        |
| `MYSQL_ROOT_PASSWORD` | `wordpress_root`                           | MySQL root password            |
| `CVP_SSH_HOST`        | `cvp`                                      | SSH alias for remote host      |
| `CVP_REMOTE_PATH`     | `/home/dh_g8vmkg/casaverdepucon.com`       | Remote WordPress root          |
| `CVP_REMOTE_URL`      | `https://casaverdepucon.com`               | Production URL (for rewrites)  |
| `CVP_LOCAL_URL`       | `http://localhost:8083`                    | Local URL (for rewrites)       |

## Directory Layout

```
casaverdepucon/
├── docker-compose.yml
├── .env                  # git-ignored; copy from table above
├── .gitignore
├── scripts/
│   ├── setup.sh          # first-time: docker up + pull-db
│   ├── pull-db.sh        # dump remote DB, import locally
│   ├── pull-files.sh     # rsync remote files to site/
│   ├── apply-local-overrides.sh  # theme, plugins, nav, contact patch
│   ├── wp.sh             # WP-CLI wrapper (runs in wpcli container)
│   ├── smoke-test.sh     # curl + WP-CLI health check
│   ├── visual-smoke-test.sh      # Playwright runner bootstrap
│   ├── visual-smoke-test.js      # Playwright test script
│   └── optimize-images-local.sh  # ImageMagick bulk resize
├── site/                 # WordPress root (git-ignored)
├── backups/              # SQL dump archives (git-ignored)
└── artifacts/
    └── visual-smoke/     # Playwright screenshots (git-ignored)
```
