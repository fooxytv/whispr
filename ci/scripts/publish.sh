#!/bin/bash

set -euo pipefail

# Usage examples:
#   ./publish.sh           # defaults to patch
#   ./publish.sh patch     # explicit patch
#   ./publish.sh none      # skip bump, just publish
#
#   or with pre-release types:
#   ./publish.sh minor alpha
#

bump_type="${1:-patch}"
pre_release_type="${2:-}"
branch="develop"

echo "Bumping (or reading) version ($bump_type) [prerelease: $pre_release_type]..."
raw_version="$(./ci/scripts/version.sh "$bump_type" "$pre_release_type")"
new_version="$(echo "$raw_version" | tr -d '[:cntrl:]')"

echo "Version to publish: [$new_version]"

echo "Committing version bump (if any changes)..."
git add .
git commit -m "Bump version to $new_version" || {
    echo "No changes to commit (or commit failed)."
}

last_tag=$(git describe --tags --abbrev=0 2>/dev/null || true)
if [[ -z "$last_tag" ]]; then
    echo "No previous tags found, so we may be generating a full changelog from the start."
    last_tag=$(git rev-list --max-parents=0 HEAD)
fi

new_tag="v${new_version}"
echo "Creating new tag: $new_tag"
git tag -a "$new_tag" -m "Release $new_version"

# changelog_file="CHANGELOG_${new_version}.md"
# echo "Generating changelog from $last_tag to $new_tag ($changelog_file)"
# {
#     echo "# Changelog for $new_tag"
#     echo
#     git log --pretty=format:"* %s (%h)" "${last_tag}..HEAD"
#     echo
# } > "$changelog_file"

# echo "Changelog generated:"
# cat "$changelog_file"
# echo

# echo "Pushing branch + tag..."
# git push origin "$branch"
# git push origin "$new_tag"

# echo "Creating GitHub release for $new_tag..."
# gh release create "$new_tag" --title "$new_tag" --notes-file "$changelog_file"

# echo "Release $new_tag created with changelog attached!"
