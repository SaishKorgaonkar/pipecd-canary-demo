#!/usr/bin/env bash
# Install the piped agent and point it at this GitOps repository.
# Usage: ./scripts/02-install-piped.sh <PIPED_ID> <BASE64_PIPED_KEY>
set -euo pipefail
PIPED_ID=${1:?piped id}
PIPED_KEY=${2:?base64 piped key}
QUICKSTART_REF=${QUICKSTART_REF:-9950863c7ea3aa564d7d585ec4e09d1a0fbdc709}  # pinned pipecd master commit (quickstart manifests, PipeCD v0.56.0)
REPO_URL=${REPO_URL:-https://github.com/SaishKorgaonkar/pipecd-canary-demo.git}
BRANCH=${BRANCH:-main}

curl -fsSL "https://raw.githubusercontent.com/pipe-cd/pipecd/${QUICKSTART_REF}/quickstart/manifests/piped.yaml" |
  sed -e "s|<YOUR_PIPED_ID>|${PIPED_ID}|g" \
      -e "s|<YOUR_PIPED_KEY_DATA>|${PIPED_KEY}|g" \
      -e "s|repoId: examples|repoId: demo|" \
      -e "s|remote: https://github.com/pipe-cd/examples.git|remote: ${REPO_URL}|" \
      -e "s|branch: master|branch: ${BRANCH}|" \
      -e "s|syncInterval: 1m|syncInterval: 10s|" |
  kubectl apply -n pipecd -f -

kubectl rollout status -n pipecd deploy/piped --timeout=300s
echo
echo ">> piped is running. In the console: Applications -> +ADD -> ADD FROM SUGGESTIONS"
echo "   piped: dev, platform provider: kubernetes-default, pick app 'web' -> SAVE"
