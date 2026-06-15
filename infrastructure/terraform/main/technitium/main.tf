# --- Create LXC --- #
locals {
  instances = {
    "technitium" = {
      vmid        = 500
      target_node = "pve"
      public_ip   = "192.168.1.50"
    }
  }
}

resource "proxmox_lxc" "technitium" {
  for_each = local.instances

  vmid            = each.value.vmid
  hostname        = each.key
  target_node     = each.value.target_node
  ostemplate      = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
  ssh_public_keys = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrNZ7JA97YCtp8zNmrF0t3XwhgOi3eytHdA057yIhRX thibaud@M1"
  pool            = "misc"
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
    ip     = "${each.value.public_ip}/24"
    gw     = "192.168.1.1"
  }

  features {
    nesting = true
  }
}


# --- Install technitium --- #
resource "terraform_data" "technitium_config" {
  for_each   = local.instances
  depends_on = [proxmox_lxc.technitium]

  connection {
    host        = each.value.public_ip
    type        = "ssh"
    user        = "root"
    private_key = file("~/.ssh/id_ed25519")
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get -qq update -y",
      "apt-get -qq install -y curl",
      "curl -sSL https://download.technitium.com/dns/install.sh | bash"
    ]
  }
}
