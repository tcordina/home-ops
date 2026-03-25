# Manageable switch VLAN configuration

## 802.1IQ VLAN

### Config

VLAN ID : 10<br>
VLAN Name : Cluster

| Port | Untagged | Tagged | Not Member |
|---|---|---|---|
| Port 1 (router) | [ ] | [ ] | [x] |
| Port 2 (pc) | [ ] | [ ] | [x] |
| Port 3 (pve) | [ ] | [x] | [ ] |
| Port 4 (pve2) | [ ] | [x] | [ ] |
| Port 5 (unused) | [ ] | [ ] | [x] |

### Recap
| VLAN ID | VLAN Name | Member Ports | Tagged Ports | Untagged Ports |
|---|---|---|---|---|
| 1 | Default | 1-5 | | 1-5 |
| 10 | Cluster | 3-4 | 3-4 | |

---

_Keep default values for PVID Setting_