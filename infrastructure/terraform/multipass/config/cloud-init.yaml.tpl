#cloud-config
package_update: true
packages:
  - open-iscsi
  - nfs-common
  - jq

locale: fr_FR
timezone: Europe/Paris

users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${ssh_public_key}

# fix grafana alloy error "failed to create fsnotify watcher: too many open files"
# https://github.com/containerd/containerd/pull/11652
write_files:
  - path: /etc/sysctl.d/99-inotify.conf
    content: |
      fs.inotify.max_user_instances=1024

runcmd:
  - systemctl enable --now iscsid
  - mkdir -p /var/mnt/longhorn
  - |
    curl -sfL https://get.k3s.io | sh -s - server \
      --cluster-init \
      --disable=coredns,traefik \
      --etcd-expose-metrics=true \
      --write-kubeconfig-mode=644
  - chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml
