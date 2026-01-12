## Todo list
- add jellyseerr & VPN config
- add [renovate](https://docs.renovatebot.com) config 
- migrate everything to oci://ghcr.io/bjw-s-labs/helm/app-template helm template (https://kubesearch.dev)
- refactor `/infrastructure` directory structure
- fix nextcloud instance probes failing
- setup alerts

---

## Infra
### Proxmox
- 2 PCs running proxmox in cluster mode on my local network
- PC 1 (192.168.1.21) :
  - [lxc] ha-proxy balancing between 3 k8s IPs (192.168.1.100)
  - [vm] k8s node "master-node-1" (192.168.1.101)
- PC 2 (192.168.1.22) :
  - [vm] k8s node "master-node-2" (192.168.1.102)
  - [vm] k8s node "master-node-3" (192.168.1.103)
  - [vm] truenas (192.168.1.30)

### Kubernetes
- k8s cluster (3 control-plane nodes) :
  - flux controllers
  - nfs provisioner
  - ingress-nginx in front of every service
  - monitoring (data stored locally) :
    - prometheus
    - grafana
    - loki
  - media server (data stored on truenas) :
    - jellyfin
      - sonarr
      - qbittorrent
    - immich
    - nextcloud
  - misc :
    - discord bot
    - gitlab ci runner
