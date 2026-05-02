#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"

source "${DIR}/../../.env"

echo -e "\nBootstrapping cluster..."

BW_TOKEN="${BW_TOKEN}" helmfile apply --kube-context "${KUBE_CONTEXT}" --skip-diff-on-install --suppress-diff --file "${DIR}/helmfile.d/00-base.yaml.gotmpl"
helmfile apply --kube-context "${KUBE_CONTEXT}" --skip-diff-on-install --suppress-diff --file "${DIR}/helmfile.d/01-flux.yaml.gotmpl"
