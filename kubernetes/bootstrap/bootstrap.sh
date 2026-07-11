#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"

source "${DIR}/../../.env"

echo -e "\nBootstrapping cluster..."

# We’re using helm template piped into kubectl apply instead of helm install due to a known Helm limitation related to large CRDs in the templates/ directory.
# https://gateway.envoyproxy.io/docs/install/install-helm/
helmfile template --file "${DIR}/helmfile.d/00-crds.yaml.gotmpl" | kubectl apply --context "${KUBE_CONTEXT}" --server-side -f -

BW_TOKEN="${BW_TOKEN}" helmfile apply --kube-context "${KUBE_CONTEXT}" --skip-diff-on-install --suppress-diff --file "${DIR}/helmfile.d/01-base.yaml.gotmpl"
helmfile apply --kube-context "${KUBE_CONTEXT}" --skip-diff-on-install --suppress-diff --file "${DIR}/helmfile.d/02-flux.yaml.gotmpl"
