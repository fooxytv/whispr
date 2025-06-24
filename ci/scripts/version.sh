#!/usr/bin/env bash

set -euo pipefail

toc_file=$(find "$(pwd)" -name "*.toc" | head -n 1)
bump_type="${1:-none}"
pre_release_type="${2:-}"
commit_hash=$(git rev-parse --short HEAD)

increment_version() {
    local version=$1
    local part=$2

    IFS='.' read -r major minor patch <<< "$version"

    case $part in
        major)
            ((major++))
            minor=0
            patch=0
            ;;
        minor)
            ((minor++))
            patch=0
            ;;
        patch)
            ((patch++))
            ;;
    esac

    echo "$major.$minor.$patch"
}

get_version_from_toc() {
    awk -F': ' '/^## Version:/ {print $2}' "$toc_file"
}

update_toc_version() {
    local new_version=$1
    sed -i.bak "s/^## Version:.*/## Version: $new_version/" "$toc_file"
    echo "Updated $toc_file with new version: $new_version" >&2
}

current_version=$(get_version_from_toc)
if [[ -z "$current_version" ]]; then
    echo "No version found in .toc file."
    exit 1
fi

if [[ "$bump_type" == "none" ]]; then
    >&2 echo "Skipping version bump. Using existing version: $current_version"
    echo "$current_version" | tr -d '\r'
    exit 0
fi

base_version=$(echo "$current_version" | sed 's/-.*//')

new_version=$(increment_version "$base_version" "$bump_type")

if [[ "$pre_release_type" == "alpha" || "$pre_release_type" == "beta" ]]; then
    new_version="$new_version-$pre_release_type.$commit_hash"
fi

update_toc_version "$new_version"
echo "$new_version"
