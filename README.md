<div align="center">

<h1>Home Operations</h1>

Personal homelab running on a 2-node Proxmox cluster. Infrastructure and application configuration is managed as code and reconciled via a GitOps operator.

Heavily inspired by the projects shared on [kubesearch.dev](https://kubesearch.dev/)

_This is a learning environment first. Certain design choices may be suboptimal or overengineered._

---

<h3>Kubernetes cluster info</h3>

![talos version](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Ftalos.json&style=for-the-badge&logo=talos&logoColor=white&logoSize=auto&color=%23E23359)
![k8s version](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fk8s.json&style=for-the-badge&logo=kubernetes&logoColor=white&logoSize=auto&color=%23326CE5)
![flux version](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fflux.json&style=for-the-badge&logo=flux&logoColor=white&logoSize=auto&color=%235468FF)

![nodes count](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fnodes.json&style=flat-square)
![pods count](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fpods.json&style=flat-square)
![cluster age](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fage.json&style=flat-square)
![alerts count](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Falerts.json&style=flat-square)
![cpu usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fcpu.json&style=flat-square)
![ram usage](https://img.shields.io/endpoint?url=https%3A%2F%2Fhomelab-233dab.gitlab.io%2Fram.json&style=flat-square)

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

| Guest      | Type | Role                           |
| ---------- | ---- | ------------------------------ |
| technitium | LXC  | DNS server                     |
| talos-node | VM   | Single-node kubernetes cluster |

#### Proxmox node 2 (custom build)

| Guest         | Type | Role               |
| ------------- | ---- | ------------------ |
| TrueNAS       | VM   | NFS storage server |

---

## Stack

### Infrastructure components

| Tool                                                                                           | Purpose                                                          |
| ---------------------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| [Proxmox VE](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview)         | Virtualization platform                                          |
| [Talos Linux](https://www.siderolabs.com/talos-linux)                                          | Kubernetes optimized Linux distro.                               |
| [TrueNAS](https://www.truenas.com/truenas-community-edition/)                                  | Provide network attached storage                                 |
| [Technitium](https://technitium.com/dns)                                                       | DNS server + network-wide ad blocking                            |

### Automation tools

| Tool                                         | Purpose                                                           |
| -------------------------------------------- | ----------------------------------------------------------------- |
| [Terraform](https://www.terraform.io/)       | Proxmox VM / LXC provisioning                                     |
| [Flux](https://fluxcd.io/)                   | GitOps operator - reconciles cluster state from this repo         |
| [Helmfile](https://helmfile.readthedocs.io/) | Deploy helm charts via declarative yaml files - used at bootstrap |
| [Taskfile](https://taskfile.dev/)            | Task runner for common repo operations                            |
| [Renovate](https://docs.renovatebot.com/)    | Automated dependency updates                                      |
| [GitLab CI](https://docs.gitlab.com/ci/)     | Validate kubernetes manifests / Run renovate / Generate badges    |

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
│   ├── talos/             # Talos node config
│   └── terraform/
│       ├── main/          # Terraform modules for the main environment
│       └── staging/       # Terraform modules for the staging environment
└── kubernetes/
    ├── apps/              # Application manifests
    ├── bootstrap/         # K8S cluster bootstrap
    ├── clusters/          # Flux entry points
    ├── components/        # Reusable Kustomize components
    └── resources/         # Cluster-wide resources
```
