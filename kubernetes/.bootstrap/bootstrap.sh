#!/bin/bash

DIR="$( cd "$( dirname "$0" )" && pwd )"

source $DIR/.env


# --- CONFIGURE KUBECTL --- #
echo -e "\nWaiting for master node to be ready..."

until [ "$(curl -ks -o /dev/null -w "%{http_code}" https://$MASTER_IP:6443)" -eq 401 ]; do
  sleep 5
  echo -n '.'
done

sleep 5

echo -e "\nConfiguring local kubectl..."
scp ubuntu@$MASTER_IP:/etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i "s/127\.0\.0\.1/$LOADBALANCER_IP/g" ~/.kube/config


# --- BOOTSTRAP CLUSTER --- #
echo -e "\nBootstrapping cluster..."

helmfile apply --debug --skip-diff-on-install --suppress-diff --file $DIR/helmfile.d/00-crds.yaml
BW_TOKEN=$BW_TOKEN helmfile apply --debug --skip-diff-on-install --suppress-diff --file $DIR/helmfile.d/01-secrets.yaml.gotmpl 
helmfile apply --debug --skip-diff-on-install --suppress-diff --file $DIR/helmfile.d/02-apps.yaml