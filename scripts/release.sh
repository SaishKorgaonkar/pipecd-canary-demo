#!/usr/bin/env bash
# "Release" a version the GitOps way: change the image tag in Git, commit, push.
# PipeCD's piped notices the new commit and starts the canary pipeline.
# Usage: ./scripts/release.sh v2      (v2 = broken, v3 = fixed)
set -euo pipefail
VERSION=${1:?usage: release.sh <v1|v2|v3>}
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

sed -i.bak -E "s|image: demo-web:v[0-9]+|image: demo-web:${VERSION}|" manifests/web/deployment.yaml
rm -f manifests/web/deployment.yaml.bak
git --no-pager diff manifests/web/deployment.yaml
git add manifests/web/deployment.yaml
git commit -q -m "release: web ${VERSION}"
git push -q
echo ">> pushed $(git rev-parse --short HEAD): web -> ${VERSION}. Watch the PipeCD console."
