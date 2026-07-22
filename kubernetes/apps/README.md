# Applications

Everything running inside the Kubernetes cluster is defined in this directory.

## Infrastructure

| Component                                                                           | Purpose                                            |
| ----------------------------------------------------------------------------------- | -------------------------------------------------- |
| [Envoy](https://gateway.envoyproxy.io/)                                             | Gateway API implementation                         |
| [cert-manager](https://cert-manager.io/)                                            | TLS certificates via Let's Encrypt                 |
| [external-secrets](https://external-secrets.io/)                                    | Load secrets from Bitwarden Secret Store           |
| [CSI Driver NFS](https://github.com/kubernetes-csi/csi-driver-nfs)                  | Provision NFS persistent volumes backed by TrueNAS |
| [OpenEBS](https://openebs.io/)                                                      | Provision local volumes via lvm-thin               |
| [Volsync](https://volsync.readthedocs.io/)                                          | Automated volume backup & restore                  |
| [snapshot-controller](https://github.com/kubernetes-csi/external-snapshotter)       | Volume snapshot support                            |
| [Crunchy Data PGO](https://access.crunchydata.com/documentation/postgres-operator/) | PostgreSQL operator                                |

## Observability

| Component                                                                                                           | Purpose                             |
| ------------------------------------------------------------------------------------------------------------------- | ----------------------------------- |
| [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) | Prometheus + Grafana + Alertmanager |
| [Loki](https://grafana.com/oss/loki/) + [Alloy](https://grafana.com/oss/alloy-opentelemetry-collector/)             | Log aggregation                     |

## Media streaming

| App                                         | Purpose                                                                       |
| ------------------------------------------- | ----------------------------------------------------------------------------- |
| [Jellyfin](https://jellyfin.org/)           | Media server                                                                  |
| [Sonarr](https://sonarr.tv/)                | TV show automation / management                                               |
| [Radarr](https://radarr.video/)             | Movie automation / management                                                 |
| [Bazarr](https://www.bazarr.media/)         | Subtitle files automation / management                                        |
| [Prowlarr](https://prowlarr.com/)           | Torrent indexer manager                                                       |
| [qBittorrent](https://www.qbittorrent.org/) | Torrent client (behind a VPN via [Gluetun](https://github.com/qdm12/gluetun)) |

## File storage

| App                                | Purpose       |
| ---------------------------------- | ------------- |
| [OpenCloud](https://opencloud.eu/) | File storage  |
| [Immich](https://immich.app/)      | Photo library |

## Authentication

| App                                                          | Purpose                                          |
| ------------------------------------------------------------ | ------------------------------------------------ |
| [Keycloak](https://www.keycloak.org/)                        | Single sign-on provider                          |

## Misc

| App                                                    | Purpose                                 |
| ------------------------------------------------------ | --------------------------------------- |
| [Discord Bot](https://gitlab.com/tcordina/discord-bot) | Custom bot running on my Discord server |
| [GitLab Runner](https://docs.gitlab.com/runner/)       | CI/CD executor                          |

---

## Directory structure

Application declaration follows this directory structure (example with Immich) :

```bash
apps
└── default               # Immich resides inside the "default" k8s namespace
    └── immich
        ├── app           # manifests for the app itself (HelmRepository, HelmRelease, Secrets)
        ├── db            # manifests for the app database (PostgresCluster, Secrets)
        └── ks.yaml       # file containing both Flux Kustomizations needed to reconcile the manifests in app/ and db/
```
