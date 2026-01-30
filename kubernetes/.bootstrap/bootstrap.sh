#!/bin/bash

DIR="$( cd "$( dirname "$0" )" && pwd )"

source $DIR/.env

echo -e "\nBootstrapping cluster..."

helmfile apply --skip-diff-on-install --suppress-diff --file $DIR/helmfile.d/00-crds.yaml
BW_TOKEN=$BW_TOKEN helmfile apply --skip-diff-on-install --suppress-diff --file $DIR/helmfile.d/01-secrets.yaml.gotmpl 
helmfile apply --skip-diff-on-install --suppress-diff --file $DIR/helmfile.d/02-apps.yaml