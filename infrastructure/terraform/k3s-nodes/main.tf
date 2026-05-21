terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc07"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
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

variable "ssh_private_key" {
  sensitive = true
  type      = string
}

locals {
  cloud_init_rendered = {
    master = templatefile("${path.module}/config/cloud-init.yaml.tpl", {
      is_master      = true
      ssh_private_key = ""
      k3s_config     = file("${path.module}/config/imports/k3s-config.yaml")
      kubelet_config = file("${path.module}/config/imports/kubelet-config.yaml")
      inotify_conf   = file("${path.module}/config/imports/99-notify.conf")
    })
    controlplane = templatefile("${path.module}/config/cloud-init.yaml.tpl", {
      is_master      = false
      ssh_private_key = var.ssh_private_key
      k3s_config     = file("${path.module}/config/imports/k3s-config.yaml")
      kubelet_config = file("${path.module}/config/imports/kubelet-config.yaml")
      inotify_conf   = file("${path.module}/config/imports/99-notify.conf")
    })
  }
}

resource "local_file" "cloud_init_rendered" {
  for_each        = local.cloud_init_rendered
  filename        = "${path.module}/config/.rendered/${each.key}.yaml"
  content         = each.value
  file_permission = "0600"
}

resource "terraform_data" "cloud-init_upload" {
  provisioner "local-exec" {
    command = <<-EOT
      scp ${path.module}/config/.rendered/master.yaml root@${var.pve_ip}:/var/lib/vz/snippets/cloud-init-master.yaml
      scp ${path.module}/config/.rendered/controlplane.yaml root@${var.pve_ip}:/var/lib/vz/snippets/cloud-init-controlplane.yaml

      scp ${path.module}/config/.rendered/master.yaml root@${var.pve2_ip}:/var/lib/vz/snippets/cloud-init-master.yaml
      scp ${path.module}/config/.rendered/controlplane.yaml root@${var.pve2_ip}:/var/lib/vz/snippets/cloud-init-controlplane.yaml
    EOT
  }

  triggers_replace = {
    master       = md5(local.cloud_init_rendered["master"])
    controlplane = md5(local.cloud_init_rendered["controlplane"])
  }

  depends_on = [local_file.cloud_init_rendered]
}

locals {
  k3s_nodes = {
    "master-node-1" = {
      vmid        = 201
      target_node = "pve"
      gateway     = "10.0.1.1"
      cores       = 4
      memory      = 12288
      ip          = "10.0.1.11"
      cloud_init  = "master"
      public_keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrNZ7JA97YCtp8zNmrF0t3XwhgOi3eytHdA057yIhRX thibaud@M1",
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH1HxNNmPvsZQFSuU8EuTn/cFwL9Jh1CUZiRvNbbP/gG other-nodes",
      ]
    }
    "master-node-2" = {
      vmid        = 202
      target_node = "pve2"
      gateway     = "10.0.1.2"
      cores       = 6
      memory      = 6144
      ip          = "10.0.1.12"
      cloud_init  = "controlplane"
      public_keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrNZ7JA97YCtp8zNmrF0t3XwhgOi3eytHdA057yIhRX thibaud@M1",
      ]
    }
    "master-node-3" = {
      vmid        = 203
      target_node = "pve2"
      gateway     = "10.0.1.2"
      cores       = 6
      memory      = 6144
      ip          = "10.0.1.13"
      cloud_init  = "controlplane"
      public_keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrNZ7JA97YCtp8zNmrF0t3XwhgOi3eytHdA057yIhRX thibaud@M1",
      ]
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
  memory              = each.value.memory
  boot                = "order=scsi0"        # has to be the same as the OS disk of the template
  clone               = "ubuntu24-cloudinit" # The name of the template
  scsihw              = "virtio-scsi-single"
  vm_state            = "running"
  automatic_reboot    = true
  start_at_node_boot  = true

  # Cloud-Init configuration
  cicustom   = "vendor=local:snippets/cloud-init-${each.value.cloud_init}.yaml" # inside /var/lib/vz/snippets/
  nameserver = "1.1.1.1 1.0.0.1"
  ipconfig0  = "ip=${each.value.ip}/24,gw=${each.value.gateway}"
  skip_ipv6  = true
  ciuser     = "ubuntu"
  cipassword = "ubuntu"
  sshkeys    = join("\n", each.value.public_keys)

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

  # 192.168.1.0/24 network
  # network {
  #   id     = 0
  #   bridge = "vmbr0"
  #   model  = "virtio"
  # }

  # 10.0.1.0/24 network
  network {
    id     = 0
    bridge = "vmbr10"
    model  = "virtio"
  }
}
