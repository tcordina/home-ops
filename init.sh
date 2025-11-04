#!/bin/bash

DIR="$( cd "$( dirname "$0" )" && pwd )"

# retrieve MASTER_IP and GITLAB_TOKEN from .env file
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
sed -i "s/127\.0\.0\.1/$MASTER_IP/g" ~/.kube/config


# --- BOOTSTRAP FLUXCD --- #
echo -e "\nBootstrapping Flux..."

kubectl create namespace flux-system
kubectl create secret generic sops-age --from-file=age.agekey=$DIR/age.agekey --namespace=flux-system

export GITLAB_TOKEN=$GITLAB_TOKEN
flux bootstrap gitlab \
    --token-auth \
    --owner=tcordina \
    --repository=homelab-flux \
    --branch=main \
    --path=clusters/main \
    --author-email flux@tablar.ovh \
    --personal
