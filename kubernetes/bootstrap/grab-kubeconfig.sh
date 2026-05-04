#!/bin/bash

DIR="$(cd "$(dirname "$0")" && pwd)"

source "${DIR}/../../.env"

KUBECONFIG_TARGET="${DIR}/../../kubeconfig"

merge_kubeconfig() {
	local tmp="$1"
	local target="$2"
	if [[ -f $target ]]; then
		KUBECONFIG="${tmp}:${target}" kubectl config view --flatten >"${tmp}.merged"
		mv "${tmp}.merged" "$target"
	else
		mv "$tmp" "$target"
	fi
	rm -f "$tmp"
}

if [[ ${KUBE_CONTEXT} == "staging" ]]; then
	VM_IP=$(multipass info staging --format json | jq -r '.info.staging.ipv4[0]')

	echo -e "\nWaiting for k3s in staging VM..."

	until
		http_code=$(curl -ks -o /dev/null -w '%{http_code}' "https://${VM_IP}:6443") || true
		[[ ${http_code} -eq 401 ]]
	do
		sleep 5
		echo -n '.'
	done

	sleep 5

	echo -e "\nConfiguring local kubectl..."

	scp "ubuntu@${VM_IP}:/etc/rancher/k3s/k3s.yaml" /tmp/kubeconfig-staging
	sed -i "s/127\.0\.0\.1/${VM_IP}/g; s/: default$/: staging/g" /tmp/kubeconfig-staging
	cat /tmp/kubeconfig-staging
	merge_kubeconfig /tmp/kubeconfig-staging "${KUBECONFIG_TARGET}"

else
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

	scp -o "ProxyJump=root@${JUMP_HOST}" "ubuntu@${MASTER_IP}:/etc/rancher/k3s/k3s.yaml" /tmp/kubeconfig-main
	sed -i "s/127\.0\.0\.1/${LOADBALANCER_IP}/g; s/: default$/: main/g" /tmp/kubeconfig-main
	merge_kubeconfig /tmp/kubeconfig-main "${KUBECONFIG_TARGET}"
fi

echo -e "\nKubeconfig saved."
