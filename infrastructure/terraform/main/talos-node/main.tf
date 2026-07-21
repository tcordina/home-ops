locals {
  talos-node = {
    vmid        = 103
    cores       = 6
    memory      = 6144
    boot_disk   = "50G"
    data_disk   = "100G"
  }
}

resource "proxmox_vm_qemu" "talos-node" {

  vmid        = local.talos-node.vmid
  name        = "talos-node"
  target_node = "pve2"
  agent       = 1
  cpu {
    cores = local.talos-node.cores
  }
  memory              = local.talos-node.memory
  boot                = "order=scsi0;ide2"
  scsihw              = "virtio-scsi-single"
  power_state         = "stopped"
  automatic_reboot    = true
  start_at_node_boot  = true

  serial {
    id = 0
  }

  disks {
    scsi {
      scsi0 {
        disk {
          storage = "local-lvm"
          size = local.talos-node.boot_disk
        }
      }
      scsi1 {
        disk {
          storage = "local-lvm"
          size = local.talos-node.data_disk
        }
      }
    }
    ide {
      ide2 {
        cdrom {
          iso = "local:iso/${var.talos_iso_file_name}"
        }
      }
    }
  }

  # 192.168.1.0/24 network
  network {
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }
}
