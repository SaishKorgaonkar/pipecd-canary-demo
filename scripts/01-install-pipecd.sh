#!/usr/bin/env bash
# Install the PipeCD Control Plane (quickstart mode) and open the web console.
set -euo pipefail
QUICKSTART_REF=${QUICKSTART_REF:-9950863c7ea3aa564d7d585ec4e09d1a0fbdc709}  # pinned pipecd master commit (quickstart manifests, PipeCD v0.56.0)

kubectl create namespace pipecd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n pipecd -f "https://raw.githubusercontent.com/pipe-cd/pipecd/${QUICKSTART_REF}/quickstart/manifests/control-plane.yaml"

echo ">> waiting for control plane pods (first pull can take a few minutes)..."
kubectl wait -n pipecd --for=condition=Available deploy --all --timeout=600s
kubectl get pods -n pipecd

cat <<'EOF'

Control plane is up. Now, in a separate terminal keep this running:
    kubectl port-forward -n pipecd svc/pipecd 8080

Open http://localhost:8080?project=quickstart   (user/pass: hello-pipecd / hello-pipecd)
Settings -> Piped -> +ADD -> name "dev" -> Save, then copy the Piped ID and the
Base64 encoded Piped Key and run:
    ./scripts/02-install-piped.sh <PIPED_ID> <BASE64_PIPED_KEY>
EOF
