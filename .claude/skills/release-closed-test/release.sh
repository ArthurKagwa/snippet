#!/usr/bin/env bash
# Upload a Snippet Android build to Google Play closed testing (or another
# track) with fastlane. Run from anywhere inside the repo.
#
#   release.sh [--track alpha|internal|production|<custom>] [--draft]
#              [--dry-run] [--skip-build] [--skip-tests] [--allow-dirty]
#
# --dry-run uploads and validates the bundle on Play without committing the
# release (supply's validate_only), so nothing reaches testers.
set -euo pipefail

track=alpha status=completed dry_run=false skip_build=false skip_tests=false allow_dirty=false
while [ $# -gt 0 ]; do
  case "$1" in
    --track) track="$2"; shift ;;
    --draft) status=draft ;;
    --dry-run) dry_run=true ;;
    --skip-build) skip_build=true ;;
    --skip-tests) skip_tests=true ;;
    --allow-dirty) allow_dirty=true ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

root=$(git rev-parse --show-toplevel)
cd "$root"
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
export FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_OPT_OUT_USAGE=1 FASTLANE_HIDE_CHANGELOG=1

key=${SNIPPET_PLAY_JSON_KEY:-$HOME/.config/snippet/play-service-account.json}
[ -f "$key" ] || { echo "No Play service account key at $key" >&2; exit 1; }
command -v fastlane >/dev/null || { echo "fastlane missing: brew install fastlane" >&2; exit 1; }

version=$(sed -n 's/^version: *//p' pubspec.yaml)
echo "==> Snippet $version -> track '$track' ($status)$($dry_run && echo ', dry run')"

# Whatever is in the working tree ships, so refuse uncommitted app code.
dirty=$(git status --porcelain -- lib pubspec.yaml pubspec.lock android/app ios assets/fonts)
if [ -n "$dirty" ] && ! $allow_dirty; then
  echo "Uncommitted app changes would ship in this build:" >&2
  echo "$dirty" >&2
  echo "Commit them, or pass --allow-dirty." >&2
  exit 1
fi

$skip_tests || { echo "==> flutter test"; flutter test; }

echo "==> fastlane release"
cd android
fastlane release track:"$track" status:"$status" skip_build:"$skip_build" dry_run:"$dry_run"

echo "==> Play tracks now"
fastlane version_codes 2>&1 | grep -E '(internal|alpha|beta|production):' | sed 's/^\[[0-9:]*\]: //'
