<div align="center">
<h1>Homelab</h1>

Personal homelab running on a 2 nodes Proxmox cluster. Infrastructure and application configuration is managed as code and reconciled via GitOps.

Heavily inspired by the manifests shared on [kubesearch.dev](https://kubesearch.dev/)
</div>

---

## Proxmox cluster

### Hardware

| Host | CPU | RAM | Storage |
|---|---|---|---|
| Acemagic Vista Mini V1 | Intel 4C | 16 GB DDR4 | 512 GB SSD |
| Spare parts custom build | AMD 8C / 16T | 16 GB DDR4 | 512 GB SSD + 2 TB HDD |

### Virtual machines & LXC

| Guest | Type | Host | Role |
|---|---|---|---|
| HAProxy | LXC | acemagic | Load balancer across k8s nodes |
| master-node-1 | VM | acemagic | Kubernetes control plane |
| master-node-2 | VM | custom build | Kubernetes control plane |
| master-node-3 | VM | custom build | Kubernetes control plane |
| TrueNAS | VM | custom build | NFS storage server |

---

## Stack

### Main infrastructure components

| Tool | Purpose |
|---|---|
| [Proxmox VE](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview) | Virtualization platform |
| [TrueNAS](https://www.truenas.com/truenas-community-edition/) | Provide network attached storage |
| [Ubuntu server](https://documentation.ubuntu.com/server/explanation/clouds/find-cloud-images/) | Host Kubernetes nodes |
| [K3s](https://k3s.io/) | Easy to deploy Kubernetes distribution |

### GitOps & Infrastructure as Code

| Tool | Purpose |
|---|---|
| [Flux CD](https://fluxcd.io/) | GitOps operator - reconciles cluster state from this repo |
| [SOPS + Age](https://github.com/getsops/sops) | Encrypted secrets at rest in Git |
| [Helm](https://helm.sh/) | Application packaging |
| [Terraform](https://www.terraform.io/) | Proxmox VM / LXC provisioning |
| [cloud-init](https://cloud-init.io/) | Server configuration |
| [Renovate](https://docs.renovatebot.com/) | Automated dependency updates |

### Kubernetes cluster infrastructure

| Component | Purpose |
|---|---|
| [ingress-nginx](https://kubernetes.github.io/ingress-nginx/) | Ingress controller |
| [cert-manager](https://cert-manager.io/) | TLS certificates via Let's Encrypt |
| [external-secrets](https://external-secrets.io/) | Load secrets from Bitwarden |
| [CSI Driver NFS](https://github.com/kubernetes-csi/csi-driver-nfs) | NFS persistent volumes backed by TrueNAS |
| [Longhorn](https://longhorn.io/) | Distributed block storage with replication across nodes |
| [snapshot-controller](https://github.com/kubernetes-csi/external-snapshotter) | Volume snapshot support for CSI drivers |
| [Crunchy Data PGO](https://access.crunchydata.com/documentation/postgres-operator/) | PostgreSQL operator |

### Applications

| App | Purpose |
|---|---|
| [Discord Bot](https://gitlab.com/tcordina/discord-bot) | Custom bot with a Python + PostgreSQL + TimescaleDB stack |
| [OpenCloud](https://opencloud.eu/) | File storage |
| [Immich](https://immich.app/) | Photo library |
| [GitLab Runner](https://docs.gitlab.com/runner/) | CI/CD executor |
| [Jellyfin](https://jellyfin.org/) | Media server |
| [Sonarr](https://sonarr.tv/) | TV show automation / management |
| [Radarr](https://radarr.video/) | Movie automation / management |
| [Prowlarr](https://prowlarr.com/) | Indexer manager |
| [qBittorrent](https://www.qbittorrent.org/) | Torrent client (behind a VPN via [Gluetun](https://github.com/qdm12/gluetun)) |

### Observability

| Component | Purpose |
|---|---|
| [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) | Prometheus + Grafana + Alertmanager |
| [Telegram bot webhook](https://core.telegram.org/bots/api#making-requests-when-getting-updates) | Receive alerts |
| [Loki](https://grafana.com/oss/loki/) | Log aggregation |

### Why do 2 control plane nodes run on the same machine?

I only have 2 physical machines, but wanted to learn how to operate a multi-node highly available cluster. Running 3 K3s server nodes lets me explore distributing ingress traffic across nodes, with HAProxy fronting the cluster and load balancing across 3 ingress-nginx pods. It also gives me a real multi-node environment to learn how to manage highly available storage with Longhorn, with volume replicas spread across nodes.

That said, this setup is **not truly highly available**. According to etcd's documentation, [with 3 nodes, the failure tolerance is 1 ](https://etcd.io/docs/v3.5/faq/#what-is-failure-tolerance). But since `master-node-2` and `master-node-3` both run on the same physical host, a single hardware failure takes out 2 etcd members at once, marking the cluster as failed and making it read-only until nodes come back up.

---

## Repository structure

```
.
├── infrastructure/
│   ├── terraform/          # Proxmox VM definitions
│   └── proxmox/            # Proxmox .conf files for VMs not provisioned via Terraform
└── kubernetes/
    ├── .bootstrap/         # Cluster bootstrap
    ├── clusters/           # Flux entry point
    ├── components/         # Reusable Kustomize components
    ├── apps/               # Application manifests
    └── infrastructure/     # Kubernetes infrastructure manifests
```
