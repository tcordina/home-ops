#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="${CACHE_DIR}/bin"

mkdir -p "${BIN_DIR}"

if [ "$(cat "${BIN_DIR}/.kubeconform.version" 2>/dev/null)" != "${KUBECONFORM_VERSION}" ]; then
  echo "[INFO] CACHE MISS - Installing kubeconform v${KUBECONFORM_VERSION}"
  curl -sL "https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz" \
    | tar xz -C "${BIN_DIR}"
  echo "${KUBECONFORM_VERSION}" > "${BIN_DIR}/.kubeconform.version"
fi

if [ "$(cat "${BIN_DIR}/.flux.version" 2>/dev/null)" != "${FLUX_VERSION}" ]; then
  echo "[INFO] CACHE MISS - Installing flux v${FLUX_VERSION}"
  curl -s https://fluxcd.io/install.sh | FLUX_VERSION=${FLUX_VERSION} bash -s -- "${BIN_DIR}"
  echo "${FLUX_VERSION}" > "${BIN_DIR}/.flux.version"
fi
