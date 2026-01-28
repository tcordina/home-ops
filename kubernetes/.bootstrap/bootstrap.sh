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

kubectl create namespace flux-system

# key generated with `$ age-keygen -o ./infrastructure/bootstrap/age.agekey`
kubectl create secret generic sops-age --from-file=age.agekey=$DIR/age.agekey --namespace=flux-system
kubectl create secret generic bitwarden-access-token --from-literal=token=$BW_TOKEN --namespace=external-secrets

helmfile apply --file $DIR/helmfile.d/crds.yaml --skip-diff-on-install --suppress-diff
kubectl apply -f $DIR/../infrastructure/flux-system/flux-instance/app/external-secret.yaml
helmfile apply --file $DIR/helmfile.d/apps.yaml --skip-diff-on-install --suppress-diff