#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAX_WIDTH="${MAX_WIDTH:-2000}"
QUALITY="${QUALITY:-88}"
DRY_RUN=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) echo "Usage: $0 [--dry-run]" >&2; exit 1 ;;
  esac
done

command -v magick >/dev/null 2>&1 || command -v mogrify >/dev/null 2>&1 || {
  echo "ImageMagick is required. Install it with: brew install imagemagick" >&2
  exit 1
}

MOGRIFY="mogrify"
if command -v magick >/dev/null 2>&1; then
  MOGRIFY="magick mogrify"
fi

UPLOADS="$PROJECT_DIR/site/wp-content/uploads"
GALLERY="$PROJECT_DIR/site/wp-content/gallery"

find "$UPLOADS" "$GALLERY" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) 2>/dev/null | while IFS= read -r file; do
  base="$(basename "$file")"
  if echo "$base" | grep -Eq '^.+-[0-9]+x[0-9]+\.[A-Za-z]+$'; then
    continue
  fi

  width="$(identify -format '%w' "$file" 2>/dev/null || true)"
  if [[ -z "$width" || "$width" -le "$MAX_WIDTH" ]]; then
    continue
  fi

  if [[ "$DRY_RUN" == true ]]; then
    echo "would resize: $file (${width}px)"
  else
    $MOGRIFY -resize "${MAX_WIDTH}x>" -quality "$QUALITY" "$file"
    echo "resized: $file"
  fi
done
