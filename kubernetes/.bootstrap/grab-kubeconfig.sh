#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"

source $DIR/.env

echo -e "\nWaiting for master node to be ready..."

until [ "$(curl -ks -o /dev/null -w "%{http_code}" https://$MASTER_IP:6443)" -eq 401 ]; do
	sleep 5
	echo -n '.'
done

sleep 5

echo -e "\nConfiguring local kubectl..."

scp ubuntu@$MASTER_IP:/etc/rancher/k3s/k3s.yaml ~/.kube/config
sed -i "s/127\.0\.0\.1/$LOADBALANCER_IP/g" ~/.kube/config
