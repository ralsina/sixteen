#!/bin/bash
set -e

echo "==================================="
echo "Sixteen Showcase Site Generator"
echo "==================================="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SITE_DIR="$SCRIPT_DIR/site"
echo "Setting up site directory..."
mkdir -p "$SITE_DIR"

# Step 1: Generate index data
echo "Step 1: Generating index data..."
cd "$SCRIPT_DIR"
crystal run site_showcase/generate-index.cr > "$SITE_DIR/index.json"
echo "  ✓ Generated index.json"

# Step 2: Render index page
echo "Step 2: Rendering index page..."
crystal run site_showcase/render-index.cr > "$SITE_DIR/index.html"
echo "  ✓ Generated index.html"

# Clean up: remove index.json (not needed for final site)
rm -f "$SITE_DIR/index.json"

# Step 3: Generate all theme pages (including auto-variants)
echo "Step 3: Generating theme showcase pages..."
crystal run gen_site.cr
echo "  ✓ Generated theme pages"

echo
echo "==================================="
echo "Site generation complete!"
echo "==================================="
echo
echo "Site generated in: $SITE_DIR"
DIR_COUNT=$(find "$SITE_DIR" -mindepth 1 -type d 2>/dev/null | wc -l)
echo "Files generated:"
echo "  - index.html (main index with theme families)"
echo "  - theme pages: $DIR_COUNT directories"
echo
echo "To view the site, open:"
echo "  file://$SITE_DIR/index.html"
