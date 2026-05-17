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

write_files:
  # K3s nodes config file
  - path: /etc/rancher/k3s/config.yaml
    content: |
      etcd-expose-metrics: true
      kube-controller-manager-arg:
      - "bind-address=0.0.0.0"
      kube-proxy-arg:
      - "metrics-bind-address=0.0.0.0"
      kube-scheduler-arg:
      - "bind-address=0.0.0.0"

  # fix grafana alloy error "failed to create fsnotify watcher: too many open files"
  # https://github.com/containerd/containerd/pull/11652
  - path: /etc/sysctl.d/99-inotify.conf
    content: |
      fs.inotify.max_user_instances=1024

runcmd:
  - apt-get remove -y multipath-tools
  - apt-get autoremove -y
  - systemctl start qemu-guest-agent
%{~ if is_master }
  - |
    curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest sh -s - server \
      --cluster-init \
      --disable=coredns,traefik \
      --tls-san=192.168.1.100 \
      --write-kubeconfig-mode=644 \
      --embedded-registry
%{~ else }
  - until [ "$(curl -ks -o /dev/null -w "%%{http_code}" https://10.0.1.11:6443)" -eq 401 ]; do sleep 5; done
  - |
    REMOTE_TOKEN=$(ssh -o StrictHostKeyChecking=no ubuntu@10.0.1.11 sudo cat /var/lib/rancher/k3s/server/node-token)
    curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest sh -s - server \
      --server https://10.0.1.11:6443 \
      --token $REMOTE_TOKEN \
      --disable=coredns,traefik \
      --tls-san=192.168.1.100 \
      --write-kubeconfig-mode=644 \
      --embedded-registry
%{~ endif }
  - chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml
  - chown ubuntu:ubuntu /var/lib/rancher/k3s/server/node-token
