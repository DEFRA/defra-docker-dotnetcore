#!/usr/bin/env bash
set -euo pipefail

# Retires a .NET version once it drops out of LTS: removes it from
# image-matrix.json and README.md, and clears its entry from the GitHub
# Dependency Graph (which would otherwise keep showing that version's
# packages forever, since nothing else would ever resubmit for it).
#
# Usage: scripts/retire-version.sh <net-version>
# Example: scripts/retire-version.sh 8.0

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <net-version>" >&2
  exit 1
fi
if ! command -v jq >/dev/null || ! command -v gh >/dev/null; then
  echo "This script requires both jq and the GitHub CLI (gh, authenticated)." >&2
  exit 1
fi

NET_VERSION="$1"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MATRIX_FILE="$REPO_ROOT/image-matrix.json"
README_FILE="$REPO_ROOT/README.md"
REPO_SLUG="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"

if ! jq -e --arg v "$NET_VERSION" '.[] | select(.netVersion == $v)' "$MATRIX_FILE" >/dev/null; then
  echo "No entry for .NET $NET_VERSION found in $MATRIX_FILE" >&2
  exit 1
fi

echo "Removing .NET $NET_VERSION from image-matrix.json"
jq --arg v "$NET_VERSION" '[.[] | select(.netVersion != $v)]' "$MATRIX_FILE" > "$MATRIX_FILE.tmp"
mv "$MATRIX_FILE.tmp" "$MATRIX_FILE"

echo "Removing the $NET_VERSION row from README.md"
grep -v "| ${NET_VERSION} " "$README_FILE" > "$README_FILE.tmp"
mv "$README_FILE.tmp" "$README_FILE"

CORRELATOR="docker-image-dotnet-$NET_VERSION"
echo "Clearing Dependency Graph entry for correlator $CORRELATOR"
# job.correlator + detector.name (not detector.version) are what GitHub uses to
# decide which snapshot is "current"; an empty manifest set clears that entry.
# detector.name must match what anchore/sbom-action's syft integration submits.
gh api "repos/$REPO_SLUG/dependency-graph/snapshots" --input - <<EOF
{
  "version": 0,
  "sha": "$(git -C "$REPO_ROOT" rev-parse origin/main)",
  "ref": "refs/heads/main",
  "job": {
    "correlator": "$CORRELATOR",
    "id": "retire-version-script"
  },
  "detector": {
    "name": "syft",
    "version": "0.0.0",
    "url": "https://github.com/anchore/syft"
  },
  "scanned": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "manifests": {}
}
EOF

echo
echo "Done. Review the diff, commit image-matrix.json and README.md, and open a PR."
echo "Verify in GitHub: Insights > Dependency graph > Dependencies that the .NET $NET_VERSION packages are gone."
