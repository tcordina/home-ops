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

locals {
  haproxy_vip = "192.168.1.100"
  haproxy_instances = {
    "haproxy-1" = {
      vmid        = 400
      target_node = "pve"
      ip          = "192.168.1.98"
      vrrp_role   = "MASTER"
      vrrp_prio   = 100
    }
    "haproxy-2" = {
      vmid        = 401
      target_node = "pve2"
      ip          = "192.168.1.99"
      vrrp_role   = "BACKUP"
      vrrp_prio   = 90
    }
  }
}

resource "proxmox_lxc" "haproxy" {
  for_each = local.haproxy_instances

  vmid            = each.value.vmid
  hostname        = each.key
  target_node     = each.value.target_node
  ostemplate      = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  ssh_public_keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrNZ7JA97YCtp8zNmrF0t3XwhgOi3eytHdA057yIhRX thibaud@M1"
  pool            = "k3s-cluster"
  unprivileged    = true
  onboot          = true
  start           = true

  cores  = 1
  memory = 512
  swap   = 0

  rootfs {
    storage = "local-lvm"
    size    = "2G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${each.value.ip}/24"
    gw     = "192.168.1.1"
  }

  features {
    nesting = true
  }
}

resource "terraform_data" "haproxy_config" {
  for_each   = local.haproxy_instances
  depends_on = [proxmox_lxc.haproxy]

  connection {
    host        = each.value.ip
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/id_ed25519")
  }

  provisioner "file" {
    source      = "${path.module}/config/haproxy.cfg"
    destination = "/tmp/haproxy.cfg"
  }

  provisioner "file" {
    content = templatefile("${path.module}/config/keepalived.conf.tpl", {
      vrrp_role     = each.value.vrrp_role
      vrrp_priority = each.value.vrrp_prio
      vip           = local.haproxy_vip
      self_ip       = each.value.ip
      peer_ip       = each.key == "haproxy-1" ? local.haproxy_instances["haproxy-2"].ip : local.haproxy_instances["haproxy-1"].ip
    })
    destination = "/tmp/keepalived.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get -qq update -y",
      "apt-get -qq install -y haproxy keepalived",
      "mv /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg",
      "mv /tmp/keepalived.conf /etc/keepalived/keepalived.conf",
      "systemctl enable --now keepalived",
      "systemctl restart haproxy",
    ]
  }
}
