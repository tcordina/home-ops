#!/usr/bin/env bash
set -euo pipefail

mkdir -p "${CACHE_DIR}/bin"

if [ "$(cat "${CACHE_DIR}/bin/.kubeconform.version" 2>/dev/null)" != "${KUBECONFORM_VERSION}" ]; then
  echo "INFO - CACHE MISS - Installing kubeconform v${KUBECONFORM_VERSION}"
  curl -sL "https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz" \
    | tar xz -C "${CACHE_DIR}/bin"
  echo "${KUBECONFORM_VERSION}" > "${CACHE_DIR}/bin/.kubeconform.version"
fi

if [ "$(cat "${CACHE_DIR}/bin/.flux.version" 2>/dev/null)" != "${FLUX_VERSION}" ]; then
  echo "INFO - CACHE MISS - Installing flux v${FLUX_VERSION}"
  curl -s https://fluxcd.io/install.sh | FLUX_VERSION=${FLUX_VERSION} bash -s -- --install-dir "${CACHE_DIR}/bin"
  echo "${FLUX_VERSION}" > "${CACHE_DIR}/bin/.flux.version"
fi
