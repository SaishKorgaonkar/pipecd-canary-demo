#!/usr/bin/env bash
# Start minikube and build the three app versions straight into its image store.
set -euo pipefail
PROFILE=${PROFILE:-pipecd-demo}
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

minikube status -p "$PROFILE" >/dev/null 2>&1 || \
  minikube start -p "$PROFILE" --driver=docker --cpus=4 --memory=6144
kubectl config use-context "$PROFILE"

build() { # tag broken color
  echo ">> building demo-web:$1 (broken=$2)"
  docker build -q -t "demo-web:$1" \
    --build-arg APP_VERSION="$1" --build-arg APP_BROKEN="$2" --build-arg APP_COLOR="$3" \
    "$ROOT/app"
  minikube -p "$PROFILE" image load "demo-web:$1"
}
build v1 false '#2563eb'   # blue, healthy
build v2 true  '#dc2626'   # red, BROKEN (returns 500)
build v3 false '#16a34a'   # green, the fix
minikube -p "$PROFILE" image ls | grep demo-web
