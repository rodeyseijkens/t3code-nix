#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_NIX="$SCRIPT_DIR/package.nix"

echo "Fetching latest version..."
API_RESPONSE=$(curl -sL "https://api.github.com/repos/pingdotgg/t3code/releases/latest")
LATEST_VERSION=$(echo "$API_RESPONSE" | jq -r '.tag_name' | sed 's/^v//')

CURRENT_VERSION=$(grep 'version = ' "$PACKAGE_NIX" | head -1 | sed 's/.*"\(.*\)".*/\1/')

echo "Current version: $CURRENT_VERSION"
echo "Latest version:  $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Already up to date!"
    exit 0
fi

echo "Fetching hash for $LATEST_VERSION..."
DOWNLOAD_URL="https://github.com/pingdotgg/t3code/releases/download/v${LATEST_VERSION}/T3-Code-${LATEST_VERSION}-x86_64.AppImage"
HASH=$(nix-prefetch-url "$DOWNLOAD_URL" 2>/dev/null)
SRI_HASH=$(nix hash convert --to sri --hash-algo sha256 "$HASH")

echo "New SRI hash: $SRI_HASH"

sed -i "s/version = \"$CURRENT_VERSION\"/version = \"$LATEST_VERSION\"/" "$PACKAGE_NIX"
sed -i "s|hash = \"sha256-[^\"]*\"|hash = \"$SRI_HASH\"|" "$PACKAGE_NIX"

echo "Updated package.nix to version $LATEST_VERSION"
