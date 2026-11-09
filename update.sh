#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_NIX="$SCRIPT_DIR/versions.nix"
RELEASES_API="https://api.github.com/repos/pingdotgg/t3code/releases"

current_version() {
    local channel="$1"
    sed -n "/$channel = {/,/};/p" "$VERSIONS_NIX" \
        | sed -n 's/.*version = "\(.*\)";/\1/p'
}

# Latest stable release (GitHub excludes pre-releases from /latest).
stable_version=$(curl -fsSL "$RELEASES_API/latest" | jq -r '.tag_name | sub("^v"; "")')
# Latest nightly pre-release.
nightly_version=$(curl -fsSL "$RELEASES_API?per_page=30" | jq -r '[.[] | select(.prerelease)][0].tag_name | sub("^v"; "")')

echo "Current stable:  $(current_version stable)"
echo "Latest stable:   $stable_version"
echo "Current nightly: $(current_version nightly)"
echo "Latest nightly:  $nightly_version"

update_channel() {
    local channel="$1" version="$2"
    local current hash url

    current=$(current_version "$channel")
    if [ "$current" = "$version" ]; then
        echo "$channel is already up to date!"
        return
    fi

    echo "Fetching hash for $channel $version..."
    url="https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage"
    hash=$(nix store prefetch-file --json "$url" | jq -r '.hash')

    echo "New $channel hash: $hash"

    sed -i "/$channel = {/,/};/ s|version = \"[^\"]*\"|version = \"$version\"|" "$VERSIONS_NIX"
    sed -i "/$channel = {/,/};/ s|hash = \"sha256-[^\"]*\"|hash = \"$hash\"|" "$VERSIONS_NIX"

    echo "Updated $channel to version $version"
}

update_channel stable "$stable_version"
update_channel nightly "$nightly_version"
