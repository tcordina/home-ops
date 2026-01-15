# Todo list
- add jellyseerr & prowlarr
- add [renovate](https://docs.renovatebot.com) config 
- migrate everything to oci://ghcr.io/bjw-s-labs/helm/app-template helm template (https://kubesearch.dev)
- fix nextcloud instance probes failing
- setup alerts

---

# Infra
## Proxmox
3 PCs running proxmox in cluster mode on my local network :
1. acemagic vista mini v1 [192.168.1.21] :
  - specs :
    - cpu : intel 4 cores
    - ram : 16gb ddr4
    - storage : ssd 512gb
  - hosting :
    - [lxc] ha-proxy balancing between 3 k8s IPs [192.168.1.100]
    - [vm] k8s node "master-node-1" [192.168.1.101]
2. custom build [192.168.1.22] :
  - specs :
    - cpu : amd 8 cores / 16 threads
    - ram : 16gb ddr4
    - storage : ssd 512gb + hdd 2tb
  - hosting :
    - [vm] k8s node "master-node-2" [192.168.1.102]
    - [vm] truenas [192.168.1.30]
3. hp elitedesk 800 g3 [192.168.1.23]
  - specs :
    - cpu : intel 4 cores
    - ram : 16gb ddr4
    - ssd 512gb
  - hosting :
    - [vm] k8s node "master-node-3" [192.168.1.103]

## Kubernetes
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
    - radarr
    - qbittorrent + gluetun
  - immich
  - nextcloud
- misc :
  - discord bot
  - gitlab ci runner
