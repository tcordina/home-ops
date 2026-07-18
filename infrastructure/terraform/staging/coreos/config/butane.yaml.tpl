variant: fcos
version: 1.5.0

passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ${ssh_public_key}
      groups:
        - wheel

storage:
  # --- OS --- #
  files:
    - path: /etc/hostname
      mode: 0644
      overwrite: true
      contents:
        inline: home-ops

    - path: /etc/locale.conf
      mode: 0644
      contents:
        inline: |
          LANG=fr_FR.UTF-8

    - path: /etc/sudoers.d/core
      mode: 0440
      contents:
        inline: |
          core ALL=(ALL) NOPASSWD:ALL

    - path: /etc/zincati/config.d/55-updates-strategy.toml
      contents:
        inline: |
          [updates]
          strategy = "periodic"
          [[updates.periodic.window]]
          days = [ "Sat", "Sun" ]
          start_time = "22:30"
          length_minutes = 60

    # --- Network --- #
    - path: /etc/NetworkManager/system-connections/enp1s0.nmconnection
      mode: 0600
      contents:
        inline: |
          [connection]
          id=enp1s0
          type=ethernet
          interface-name=enp1s0

          [ipv4]
          method=manual
          address1=${vm_ip}/24
          gateway=${vm_gateway}
          dns=${vm_dns}

          [ipv6]
          method=disabled

    # --- K3S --- #
    - path: /etc/rancher/k3s/config.yaml
      mode: 0644
      contents:
        inline: |
          disable:
            - "coredns"
            - "traefik"
          write-kubeconfig-mode: "0644"
          cluster-init: true
          etcd-expose-metrics: true
          embedded-registry: false
          kubelet-arg:
            - "config=/etc/rancher/k3s/kubelet-config.yaml"

    - path: /etc/rancher/k3s/kubelet-config.yaml
      mode: 0644
      contents:
        inline: |
          kind: KubeletConfiguration
          apiVersion: kubelet.config.k8s.io/v1beta1
          imageMaximumGCAge: "120h"

  # Official docs advises against setting a TZ other than UTC: https://docs.fedoraproject.org/en-US/fedora-coreos/time-zone/
  # links:
  #   - path: /etc/localtime
  #     target: /usr/share/zoneinfo/Europe/Paris

systemd:
  units:
    - name: serial-getty@ttyS0.service
      enabled: true
      dropins:
        - name: autologin-core.conf
          contents: |
            [Service]
            ExecStart=
            ExecStart=-/sbin/agetty --autologin core --noclear %I $TERM

    - name: lvm-setup.service
      enabled: true
      contents: |
        [Unit]
        Description=Initialize LVM thin pool on /dev/vdb
        ConditionPathExists=!/dev/data-vg/thin-pool
        After=dev-vdb.device
        Requires=dev-vdb.device

        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/sbin/pvcreate /dev/vdb
        ExecStart=/sbin/vgcreate data-vg /dev/vdb
        ExecStart=/sbin/lvcreate -l 90%%FREE --thin data-vg/thin-pool

        [Install]
        WantedBy=multi-user.target

    - name: k3s-download.service
      enabled: true
      contents: |
        [Unit]
        Description=Download K3s binary
        ConditionPathExists=!/usr/local/bin/k3s
        After=network-online.target
        Wants=network-online.target

        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/bin/bash -c 'curl -fsSL -o /usr/local/bin/k3s https://github.com/k3s-io/k3s/releases/download/v1.36.2%%2Bk3s1/k3s && chmod 0755 /usr/local/bin/k3s'
        Restart=on-failure
        RestartSec=30s

        [Install]
        WantedBy=multi-user.target

    - name: "k3s.service"
      enabled: true
      contents: |
        [Unit]
        Description=Run K3s
        Wants=network-online.target lvm-setup.service k3s-download.service
        After=network-online.target lvm-setup.service k3s-download.service
        Requires=lvm-setup.service k3s-download.service

        [Service]
        Type=notify
        EnvironmentFile=-/etc/default/%N
        EnvironmentFile=-/etc/sysconfig/%N
        EnvironmentFile=-/etc/systemd/system/%N.env
        KillMode=process
        Delegate=yes
        LimitNOFILE=1048576
        LimitNPROC=infinity
        LimitCORE=infinity
        TasksMax=infinity
        TimeoutStartSec=0
        Restart=always
        RestartSec=5s
        ExecStartPre=-/sbin/modprobe br_netfilter
        ExecStartPre=-/sbin/modprobe overlay
        ExecStart=/usr/local/bin/k3s server

        [Install]
        WantedBy=multi-user.target
