#!/usr/bin/env bash
# build-skill-bundles.sh — build one zip per skill in dist/, for agents that
# import skills by hand (Gemini). SKILL.md sits at each zip's root. Built from
# committed state, so stray local files such as .DS_Store stay out.
#
# Usage: scripts/build-skill-bundles.sh [<git-ref>]    (default: HEAD)
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
ref="${1:-HEAD}"
dist="$root/dist"
last_tag="$(git -C "$root" describe --tags --abbrev=0 "$ref" 2>/dev/null || true)"

rm -rf "$dist"
mkdir -p "$dist"

while IFS= read -r skill; do
    git -C "$root" archive --format=zip -o "$dist/$skill.zip" "$ref:skills/$skill"
    state="new or unknown"
    if [[ -n "$last_tag" ]]; then
        if git -C "$root" diff --quiet "$last_tag" "$ref" -- "skills/$skill"; then
            state="unchanged since $last_tag"
        else
            state="CHANGED since $last_tag: replace it"
        fi
    fi
    echo "$skill.zip — $state"
done < <(git -C "$root" ls-tree --name-only "$ref:skills")
