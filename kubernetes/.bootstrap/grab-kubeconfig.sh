#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"

source "${DIR}/.env"

echo -e "\nWaiting for master node to be ready..."

until
	http_code=$(curl -ks -o /dev/null -w '%{http_code}' "https://${LOADBALANCER_IP}:6443") || true
	[[ ${http_code} -eq 401 ]]
do
	sleep 5
	echo -n '.'
done

sleep 5

echo -e "\nConfiguring local kubectl..."

scp -o "ProxyJump=root@${JUMP_HOST}" "ubuntu@${MASTER_IP}:/etc/rancher/k3s/k3s.yaml" ~/.kube/config
sed -i "s/127\.0\.0\.1/${LOADBALANCER_IP}/g" ~/.kube/config
