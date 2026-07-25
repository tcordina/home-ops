#!/usr/bin/env bash

set -euo pipefail

KUBERNETES_DIR=$1

[[ -z "${KUBERNETES_DIR}" ]] && echo "Kubernetes location not specified" && exit 1

kubeconform_args=(
    "-strict"
    "-ignore-missing-schemas"
    "-skip"
    "Gateway,HTTPRoute,Secret"
    "-schema-location"
    "default"
    "-schema-location"
    "https://k8s-schemas.home-operations.com/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json"
    "-verbose"
)

validate() {
    local name=$1
    local ks_file=$2
    local path=$3

    echo "INFO - Validating ${ks_file}"
    flux build kustomization "$name" \
        --path "$path" \
        --kustomization-file "$ks_file" \
        --dry-run \
        | kubeconform "${kubeconform_args[@]}"

    if [[ ${PIPESTATUS[0]} != 0 || ${PIPESTATUS[1]} != 0 ]]; then
        echo "ERROR - Validation failed for ${ks_file}"
        exit 1
    fi
}

echo "INFO - Validating kustomizations in ${KUBERNETES_DIR}/clusters"
find "${KUBERNETES_DIR}/clusters" -type f -name "cluster.yaml" -print0 | while IFS= read -r -d $'\0' file;
do
    dir=$(dirname "$file")
    name=$(basename "$dir")
    validate "apps" "$file" "$dir"
done

echo "INFO - Validating kustomizations in ${KUBERNETES_DIR}/apps"
find "${KUBERNETES_DIR}/apps" -type f -name "ks.yaml" -not -path "**/unused/*" -print0 | while IFS= read -r -d $'\0' file;
do
    ks_dir=$(dirname "$file")
    name=$(basename "$ks_dir")
    app_path="${ks_dir}/app"

    [[ ! -d "$app_path" ]] && continue

    validate "$name" "$file" "$app_path"
done
