<div align="center">

<h1>Homelab</h1>

![Static Badge](https://img.shields.io/badge/renovate-%23308BE3?style=for-the-badge&logo=renovate&logoColor=white&label=powered%20by)

**Kubernetes cluster info**

![ubuntu version](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fubuntu.json&style=for-the-badge&logo=ubuntu&logoColor=white&logoSize=auto)
![k3s version](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fk3s.json&style=for-the-badge&logo=k3s&logoColor=white&logoSize=auto)
![flux version](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fflux.json&style=for-the-badge&logo=flux&logoColor=white&logoSize=auto)

![nodes count](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fnodes.json&style=flat-square)
![pods count](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fpods.json&style=flat-square)
![cluster age](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fage.json&style=flat-square)
![alerts count](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Falerts.json&style=flat-square)
![cpu usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fcpu.json&style=flat-square)
![ram usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fram.json&style=flat-square)
![free disk space](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fdisk.json&style=flat-square)

<br>

Personal homelab running on a 2-node Proxmox cluster. Infrastructure and application configuration is managed as code and reconciled via GitOps.

Heavily inspired by the projects shared on [kubesearch.dev](https://kubesearch.dev/)

_This is a learning environment first. Certain design choices may be suboptimal or overengineered._

</div>

---

## Proxmox cluster

### Hardware

| Host                     | CPU          | RAM        | Storage               |
| ------------------------ | ------------ | ---------- | --------------------- |
| Acemagic Vista Mini V1   | Intel 4C     | 16 GB DDR4 | 512 GB SSD            |
| Spare parts custom build | AMD 6C / 12T | 16 GB DDR4 | 512 GB SSD + 2 TB HDD |

### Virtual machines & LXC

#### Proxmox node 1 (acemagic)

| Guest         | Type | Role                        |
| ------------- | ---- | --------------------------- |
| haproxy-1     | LXC  | Load balancer + VRRP master |
| technitium    | LXC  | DNS server                  |
| master-node-1 | VM   | Kubernetes node             |

#### Proxmox node 2 (custom build)

| Guest         | Type | Role                        |
| ------------- | ---- | --------------------------- |
| haproxy-2     | LXC  | Load balancer + VRRP backup |
| master-node-2 | VM   | Kubernetes node             |
| master-node-3 | VM   | Kubernetes node             |
| TrueNAS       | VM   | NFS storage server          |

_All 3 Kubernetes nodes act as both control plane and worker nodes._

---

## Stack

### Infrastructure components

| Tool                                                                                           | Purpose                                                          |
| ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| [Proxmox VE](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview)         | Virtualization platform                                          |
| [Technitium](https://technitium.com/dns)                                                       | DNS server + network-wide ad blocking                            |
| [TrueNAS](https://www.truenas.com/truenas-community-edition/)                                  | Provide network attached storage                                 |
| [Ubuntu server](https://documentation.ubuntu.com/server/explanation/clouds/find-cloud-images/) | Host Kubernetes nodes                                            |
| [K3s](https://k3s.io/)                                                                         | Easy to deploy Kubernetes distribution                           |
| [HAProxy](https://www.haproxy.org/)                                                            | Load balancer distributing traffic across Kubernetes nodes       |
| [Keepalived](https://www.keepalived.org/)                                                      | VRRP-based virtual IP failover between the two HAProxy instances |

### Automation tools

| Tool                                         | Purpose                                                           |
| -------------------------------------------- | ----------------------------------------------------------------- |
| [Terraform](https://www.terraform.io/)       | Proxmox VM / LXC provisioning                                     |
| [cloud-init](https://cloud-init.io/)         | Server configuration                                              |
| [Flux](https://fluxcd.io/)                   | GitOps operator - reconciles cluster state from this repo         |
| [Helmfile](https://helmfile.readthedocs.io/) | Deploy helm charts via declarative yaml files - used at bootstrap |
| [Taskfile](https://taskfile.dev/)            | Task runner for common repo operations                            |
| [Renovate](https://docs.renovatebot.com/)    | Automated dependency updates                                      |

---

## Applications

Check the [`/kubernetes/apps`](/kubernetes/apps#applications) directory for a list of what runs inside the cluster

---

## Staging environment

The staging environment runs a single K3s node inside a local VM, providing an environment as close as possible to the production cluster without requiring dedicated hardware. The VM is provisioned using [Multipass](https://multipass.run/) (a lightweight tool that spins up Ubuntu VMs) via [this Terraform provider](https://registry.terraform.io/providers/larstobi/multipass). Configuration files reside in [`/infrastructure/terraform/staging/multipass`](/infrastructure/terraform/staging/multipass)

Flux reconciles from the [`/kubernetes/clusters/staging`](/kubernetes/clusters/staging) directory, which tracks the `staging` branch. Environment-specific overrides are defined inside [`cluster.yaml`](/kubernetes/clusters/staging/cluster.yaml)

---

## Repository structure

```bash
.
├── infrastructure/
│   ├── proxmox/
│   │   ├── network/       # Network config for PVE hosts
│   │   └── vms/           # .conf files for VMs not provisioned via Terraform
│   └── terraform/
│       ├── main/          # Terraform modules for the main environment
│       └── staging/       # Terraform modules for the staging environment
└── kubernetes/
    ├── apps/              # Application manifests
    ├── bootstrap/         # K8S cluster bootstrap
    ├── clusters/          # Flux entry points
    └── components/
        ├── replacements/  # Reusable Kustomize components
        └── resources/     # Cluster-wide resources
```
