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
  - systemctl enable --now iscsid
  - mkdir -p /var/mnt/longhorn
  - |
    curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL=latest sh -s - server \
      --cluster-init \
      --disable=coredns,traefik \
      --write-kubeconfig-mode=644
  - chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml
