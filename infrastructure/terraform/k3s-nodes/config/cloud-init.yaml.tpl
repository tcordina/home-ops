# cloud-config
package_update: true
package_upgrade: false
packages:
  - curl
  - qemu-guest-agent
  - nfs-common

users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

locale: fr_FR
timezone: Europe/Paris

%{~ if !is_master }
# SSH private key to connect to the master node
# The public key is added to the master node's authorized_keys file in the main.tf config file
write_files:
  - path: /root/.ssh/id_ed25519
    content: |
${indent(6, ssh_private_key)}
    permissions: "0600"
%{~ endif }

runcmd:
  - systemctl start qemu-guest-agent
%{~ if is_master }
  - |
    curl -sfL https://get.k3s.io | sh -s - server \
      --cluster-init \
      --disable=coredns,traefik \
      --tls-san=192.168.1.100 \
      --etcd-expose-metrics=true \
      --write-kubeconfig-mode=644 \
      --embedded-registry
%{~ else }
  - until [ "$(curl -ks -o /dev/null -w "%%{http_code}" https://10.0.1.11:6443)" -eq 401 ]; do sleep 5; done
  - REMOTE_TOKEN=$(ssh -o StrictHostKeyChecking=accept-new ubuntu@10.0.1.11 sudo cat /var/lib/rancher/k3s/server/node-token)
  - |
    curl -sfL https://get.k3s.io | sh -s - server \
      --server https://10.0.1.11:6443 \
      --token $REMOTE_TOKEN \
      --disable=coredns,traefik \
      --tls-san=192.168.1.100 \
      --etcd-expose-metrics=true \
      --write-kubeconfig-mode=644 \
      --embedded-registry
%{~ endif }
  - chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml
  - chown ubuntu:ubuntu /var/lib/rancher/k3s/server/node-token
