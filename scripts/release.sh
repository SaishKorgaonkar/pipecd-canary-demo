#!/usr/bin/env bash
# "Release" a version the GitOps way: change the image tag in Git, commit, push.
# PipeCD's piped notices the new commit and starts the canary pipeline.
# Usage: ./scripts/release.sh v2      (v2 = broken, v3 = fixed)
# Output is also appended to stage/.terminal.log so the demo stage page shows it.
set -euo pipefail
VERSION=${1:?usage: release.sh <v1|v2|v3>}
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$ROOT/stage/.terminal.log"
cd "$ROOT"

{
  [ "${STAGE_TYPED:-}" = 1 ] || echo "\$ ./scripts/release.sh ${VERSION}"
  sed -i.bak -E "s|image: demo-web:v[0-9]+|image: demo-web:${VERSION}|" manifests/web/deployment.yaml
  rm -f manifests/web/deployment.yaml.bak
  git --no-pager diff -U0 manifests/web/deployment.yaml | grep -E '^[-+] ' || true
  git add manifests/web/deployment.yaml
  git commit -q -m "release: web ${VERSION}"
  echo "\$ git push"
  git push -q 2>&1
  echo ">> pushed $(git rev-parse --short HEAD): web -> ${VERSION}. PipeCD will pick it up."
} 2>&1 | tee -a "$LOG"
