#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSIONS_NIX="$SCRIPT_DIR/versions.nix"
RELEASES_API="https://api.github.com/repos/pingdotgg/t3code/releases"
ASSET_PATTERN='^T3-Code.*x86_64\.AppImage$'
GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

# GitHub's REST API rate limits anonymous requests per IP, and hosted runners
# share egress addresses, so scheduled runs hit HTTP 403 (rate limited) often.
# Use the token the workflow passes in and stay anonymous for local runs.
api_get() {
    local -a auth=()
    if [ -n "$GITHUB_TOKEN" ]; then
        auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
    fi

    if ! curl -fsSL --retry 3 --retry-delay 2 --retry-connrefused \
        -H "Accept: application/vnd.github+json" \
        ${auth[@]+"${auth[@]}"} "$@"; then
        echo "error: GitHub API request failed: $*" >&2
        if [ -z "$GITHUB_TOKEN" ]; then
            echo "hint: set GITHUB_TOKEN, anonymous requests are rate limited per IP" >&2
        fi
        return 1
    fi
}

channel_field() {
    local channel="$1" key="$2"
    sed -n "/$channel = {/,/};/p" "$VERSIONS_NIX" \
        | sed -n "s/.*$key = \"\(.*\)\";/\1/p"
}

# Download URL of the Linux x86_64 AppImage published with a release. Upstream
# used to name it T3-Code-<version>-x86_64.AppImage; newer nightly releases ship
# it as T3-Code-Nightly-x86_64.AppImage, so prefer the versioned name when it
# exists and fall back to whatever AppImage the release actually contains.
asset_url() {
    local version="$1"
    api_get "$RELEASES_API/tags/v${version}" \
        | jq -er --arg version "$version" --arg pattern "$ASSET_PATTERN" '
            [.assets[].name | select(test($pattern))] as $names
            | (($names | map(select(contains($version))) | first) // ($names | first))
            | "https://github.com/pingdotgg/t3code/releases/download/v\($version)/\(.)"
          '
}

releases_json=$(api_get "$RELEASES_API?per_page=50")

# Latest stable release (GitHub excludes pre-releases from /latest).
stable_version=$(api_get "$RELEASES_API/latest" | jq -r '.tag_name | sub("^v"; "")')

# Newest nightly that actually ships an x86_64 AppImage. Restricting tags to the
# v<version>-nightly.* shape skips unrelated pre-releases such as update-feed,
# and requiring the asset avoids pointing at a release without a Linux build.
nightly_version=$(jq -er --arg pattern "$ASSET_PATTERN" '
    [.[]
     | select(.prerelease and (.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+-nightly\\.")))
     | select(any(.assets[].name; test($pattern)))]
    | sort_by(.published_at)
    | last
    | .tag_name
    | sub("^v"; "")
  ' <<<"$releases_json")

echo "Current stable:  $(channel_field stable version)"
echo "Latest stable:   $stable_version"
echo "Current nightly: $(channel_field nightly version)"
echo "Latest nightly:  $nightly_version"

declare -A NEW_VERSION=() NEW_HASH=() NEW_URL=()

update_channel() {
    local channel="$1" version="$2"
    local current_version current_url url hash

    url=$(asset_url "$version")
    current_version=$(channel_field "$channel" version)
    current_url=$(channel_field "$channel" url)

    NEW_VERSION[$channel]="$version"
    NEW_URL[$channel]="$url"

    if [ "$current_version" = "$version" ] && [ "$current_url" = "$url" ]; then
        echo "$channel is already up to date!"
        NEW_HASH[$channel]=$(channel_field "$channel" hash)
        return 0
    fi

    echo "Fetching hash for $channel $version..."
    echo "  $url"
    hash=$(nix store prefetch-file --json "$url" | jq -r '.hash')
    echo "New $channel hash: $hash"

    NEW_HASH[$channel]="$hash"
    echo "Updated $channel to version $version"
}

update_channel stable "$stable_version"
update_channel nightly "$nightly_version"

cat > "$VERSIONS_NIX" <<EOF
{
  stable = {
    version = "${NEW_VERSION[stable]}";
    hash = "${NEW_HASH[stable]}";
    url = "${NEW_URL[stable]}";
  };

  nightly = {
    version = "${NEW_VERSION[nightly]}";
    hash = "${NEW_HASH[nightly]}";
    url = "${NEW_URL[nightly]}";
  };
}
EOF
