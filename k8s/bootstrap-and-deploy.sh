#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${NAMESPACE:-default}"
K8S_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KUBECTL="sudo kubectl"

cleanup() {
  $KUBECTL -n "$NAMESPACE" delete pod pizzaclaw-onboard --ignore-not-found >/dev/null 2>&1 || true
}

trap cleanup EXIT

echo "[1/6] Applying PVC..."
$KUBECTL -n "$NAMESPACE" apply -f "$K8S_DIR/pvc.yaml"

echo "[2/6] Creating onboard pod..."
$KUBECTL -n "$NAMESPACE" apply -f "$K8S_DIR/onboard-pod.yaml"

echo "[3/6] Waiting for onboard pod to be Ready..."
$KUBECTL -n "$NAMESPACE" wait --for=condition=Ready pod/pizzaclaw-onboard --timeout=120s

echo "[4/6] Attaching to onboard pod (complete prompts, then exit)..."
$KUBECTL -n "$NAMESPACE" attach -it pod/pizzaclaw-onboard

echo "[5/6] Onboard pod will be removed..."
$KUBECTL -n "$NAMESPACE" delete pod pizzaclaw-onboard --ignore-not-found

echo "[6/6] Applying deployment and service..."
$KUBECTL -n "$NAMESPACE" apply -f "$K8S_DIR/deployment.yaml" -f "$K8S_DIR/service.yaml"

echo "Done. pizzaclaw is deployed in namespace: $NAMESPACE"
