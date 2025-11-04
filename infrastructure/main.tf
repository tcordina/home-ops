terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.2-rc05"
    }
  }
}

variable "proxmox_api_token" {
  sensitive = true
}

provider "proxmox" {
  pm_api_url          = "https://192.168.1.21:8006/api2/json"
  pm_api_token_id     = "terraform-prov@pve!mytoken"
  pm_api_token_secret = var.proxmox_api_token
  pm_tls_insecure     = true
  pm_debug            = true
}

data "local_file" "cloud_init-master" {
  filename = "${path.module}/cloud-init-master.yaml"
}

data "local_file" "cloud_init-worker" {
  filename = "${path.module}/cloud-init-worker.yaml"
}

resource "null_resource" "cloud_init_upload" {
  provisioner "local-exec" {
    command = <<-EOT
      scp ${path.module}/cloud-init-master.yaml root@192.168.1.21:/var/lib/vz/snippets/cloud-init-master.yaml
      scp ${path.module}/cloud-init-worker.yaml root@192.168.1.21:/var/lib/vz/snippets/cloud-init-worker.yaml
    EOT
  }
  
  triggers = {
    cloud_init-master_hash = md5(data.local_file.cloud_init-master.content)
    cloud_init-worker_hash = md5(data.local_file.cloud_init-worker.content)
  }
}

resource "proxmox_pool" "k3s-pool" {
  poolid  = "k3s-cluster" 
  comment = ""
}

resource "proxmox_vm_qemu" "master-node" {
  vmid        = 200
  name        = "master-node"
  target_node = "pve"
  pool        = "k3s-cluster"
  agent       = 1
  cpu {
    cores     = 2
  }
  memory      = 2048
  boot        = "order=scsi0" # has to be the same as the OS disk of the template
  clone       = "ubuntu24-cloudinit" # The name of the template
  scsihw      = "virtio-scsi-single"
  vm_state    = "running"
  automatic_reboot = true

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/cloud-init-master.yaml" # inside /var/lib/vz/snippets/
  nameserver = "1.1.1.1 1.0.0.1"
  ipconfig0  = "ip=192.168.1.100/24,gw=192.168.1.1"
  ipconfig1  = "ip=10.0.1.1/24"
  skip_ipv6  = true
  ciuser     = "ubuntu"
  cipassword = "ubuntu"
  sshkeys    = <<EOT
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrNZ7JA97YCtp8zNmrF0t3XwhgOi3eytHdA057yIhRX thibaud@M1
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1HxNNmPvsZQFSuU8EuTn/cFwL9Jh1CUZiRvNbbP/gG worker-nodes
EOT

  # sshkeys    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrNZ7JA97YCtp8zNmrF0t3XwhgOi3eytHdA057yIhRX thibaud@M1"
  depends_on = [proxmox_pool.k3s-pool, null_resource.cloud_init_upload]

  # Most cloud-init images require a serial device for their display
  serial {
    id = 0
  }

  disks {
    scsi {
      scsi0 {
        # We have to specify the disk from our template, else Terraform will think it's not supposed to be there
        disk {
          storage = "local-lvm"
          # The size of the disk should be at least as big as the disk in the template. If it's smaller, the disk will be recreated
          size    = "10G" 
        }
      }
    }
    ide {
      # Some images require a cloud-init disk on the IDE controller, others on the SCSI or SATA controller
      ide1 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    id = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Create the corresponding bridge in the proxmox UI
  # pve > system > network > create > linux bridge > ipv4 10.0.1.0 > create > apply configuration
  network {
    id = 1
    bridge = "vmbr10"
    model = "virtio"
  }
}

resource "proxmox_vm_qemu" "worker-nodes" {
  count = 2

  vmid        = "${200 + count.index+1}"
  name        = "worker-node-${count.index+1}"
  target_node = "pve"
  pool        = "k3s-cluster"
  agent       = 1
  cpu {
    cores     = 3
  }
  memory      = 3072
  boot        = "order=scsi0" # has to be the same as the OS disk of the template
  clone       = "ubuntu24-cloudinit" # The name of the template
  scsihw      = "virtio-scsi-single"
  vm_state    = "running"
  automatic_reboot = true

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/cloud-init-worker.yaml" # inside /var/lib/vz/snippets/
  nameserver = "1.1.1.1 1.0.0.1"
  ipconfig0  = "ip=192.168.1.${100 + count.index+1}/24,gw=192.168.1.1"
  ipconfig1  = "ip=10.0.1.${count.index+2}/24"
  skip_ipv6  = true
  ciuser     = "ubuntu"
  cipassword = "ubuntu"
  sshkeys    = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrNZ7JA97YCtp8zNmrF0t3XwhgOi3eytHdA057yIhRX thibaud@M1"

  depends_on = [proxmox_pool.k3s-pool, null_resource.cloud_init_upload, proxmox_vm_qemu.master-node]

  # Most cloud-init images require a serial device for their display
  serial {
    id = 0
  }

  disks {
    scsi {
      scsi0 {
        # We have to specify the disk from our template, else Terraform will think it's not supposed to be there
        disk {
          storage = "local-lvm"
          # The size of the disk should be at least as big as the disk in the template. If it's smaller, the disk will be recreated
          size    = "20G" 
        }
      }
    }
    ide {
      # Some images require a cloud-init disk on the IDE controller, others on the SCSI or SATA controller
      ide1 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    id = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  network {
    id = 1
    bridge = "vmbr10"
    model = "virtio"
  }
}
