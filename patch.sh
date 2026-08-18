#!/usr/bin/env bash
set -euo pipefail

PATCH_FILE="${1:?usage: patch.sh <patches.yaml>}"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/all.yaml"          # rendered manifests from Helm via stdin

{
  echo "apiVersion: kustomize.config.k8s.io/v1beta1"
  echo "kind: Kustomization"
  echo "resources: [all.yaml]"
  echo "patches:"
  sed 's/^/  /' "$PATCH_FILE"      # indent user's list under 'patches:'
} > "$WORKDIR/kustomization.yaml"

kubectl kustomize build "$WORKDIR"
