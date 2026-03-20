terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

variable "pve_ip" {
  sensitive = false
  type      = string
}

variable "pve2_ip" {
  sensitive = false
  type      = string
}

variable "proxmox_api_token" {
  sensitive = true
  type      = string
}

provider "proxmox" {
  pm_api_url          = "https://${var.pve_ip}:8006/api2/json"
  pm_api_token_id     = "terraform-prov@pve!mytoken"
  pm_api_token_secret = var.proxmox_api_token
  pm_tls_insecure     = true
  pm_debug            = true
}

data "local_file" "cloud-init_master" {
  filename = "${path.module}/cloud-init/master.yaml"
}

data "local_file" "cloud-init_controlplane" {
  filename = "${path.module}/cloud-init/controlplane.yaml"
}

data "local_file" "cloud-init_worker" {
  filename = "${path.module}/cloud-init/worker.yaml"
}

resource "terraform_data" "cloud-init_upload" {
  provisioner "local-exec" {
    command = <<-EOT
      scp ${path.module}/cloud-init/master.yaml root@${var.pve_ip}:/var/lib/vz/snippets/cloud-init-master.yaml
      scp ${path.module}/cloud-init/controlplane.yaml root@${var.pve_ip}:/var/lib/vz/snippets/cloud-init-controlplane.yaml
      scp ${path.module}/cloud-init/worker.yaml root@${var.pve_ip}:/var/lib/vz/snippets/cloud-init-worker.yaml

      scp ${path.module}/cloud-init/master.yaml root@${var.pve2_ip}:/var/lib/vz/snippets/cloud-init-master.yaml
      scp ${path.module}/cloud-init/controlplane.yaml root@${var.pve2_ip}:/var/lib/vz/snippets/cloud-init-controlplane.yaml
      scp ${path.module}/cloud-init/worker.yaml root@${var.pve2_ip}:/var/lib/vz/snippets/cloud-init-worker.yaml
    EOT
  }

  triggers_replace = {
    cloud-init_master_hash       = md5(data.local_file.cloud-init_master.content)
    cloud-init_controlplane-hash = md5(data.local_file.cloud-init_controlplane.content)
    cloud-init_worker_hash       = md5(data.local_file.cloud-init_worker.content)
  }
}

locals {
  k3s_nodes = {
    "master-node-1" = {
      vmid        = 201
      target_node = "pve"
      cores       = 4
      memory      = 12288
      ip          = "192.168.1.101"
      cloud_init  = "master"
    }
    "master-node-2" = {
      vmid        = 202
      target_node = "pve2"
      cores       = 6
      memory      = 6144
      ip          = "192.168.1.102"
      cloud_init  = "controlplane"
    }
    "master-node-3" = {
      vmid        = 203
      target_node = "pve2"
      cores       = 6
      memory      = 6144
      ip          = "192.168.1.103"
      cloud_init  = "controlplane"
    }
  }
}

resource "proxmox_pool" "k3s-pool" {
  poolid  = "k3s-cluster"
  comment = ""
}

resource "proxmox_vm_qemu" "k3s-nodes" {
  for_each = local.k3s_nodes

  vmid        = each.value.vmid
  name        = each.key
  target_node = each.value.target_node
  pool        = "k3s-cluster"
  agent       = 1
  cpu {
    cores = each.value.cores
  }
  memory           = each.value.memory
  boot             = "order=scsi0"        # has to be the same as the OS disk of the template
  clone            = "ubuntu24-cloudinit" # The name of the template
  scsihw           = "virtio-scsi-single"
  vm_state         = "running"
  automatic_reboot = true

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/cloud-init-${each.value.cloud_init}.yaml" # inside /var/lib/vz/snippets/
  nameserver = "1.1.1.1 1.0.0.1"
  ipconfig0  = "ip=${each.value.ip}/24,gw=192.168.1.1"
  # ipconfig1  = "ip=10.0.1.x/24"
  skip_ipv6  = true
  ciuser     = "ubuntu"
  cipassword = "ubuntu"
  sshkeys    = <<EOT
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrNZ7JA97YCtp8zNmrF0t3XwhgOi3eytHdA057yIhRX thibaud@M1
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1HxNNmPvsZQFSuU8EuTn/cFwL9Jh1CUZiRvNbbP/gG other-nodes
  EOT

  depends_on = [proxmox_pool.k3s-pool, terraform_data.cloud-init_upload]

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
          size = "150G"
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
    id     = 0
    bridge = "vmbr0"
    model  = "virtio"
  }

  # Create the corresponding bridge in the proxmox UI
  # pve > system > network > create > linux bridge > ipv4 10.0.1.0 > create > apply configuration
  # network {
  #   id     = 1
  #   bridge = "vmbr10"
  #   model  = "virtio"
  # }
}
