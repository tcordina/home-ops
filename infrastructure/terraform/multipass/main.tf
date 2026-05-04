terraform {
  required_providers {
    multipass = {
      source  = "larstobi/multipass"
      version = "1.4.3"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.8.0"
    }
  }
}

variable "ssh_public_key" {
  sensitive = false
  type      = string
}

variable "ubuntu_img_path" {
  sensitive = false
  type      = string
}

locals {
  cloud_init_rendered = templatefile("${path.module}/config/cloud-init.yaml.tpl", {
    ssh_public_key = var.ssh_public_key
  })
}

resource "local_file" "cloud_init" {
  filename        = "${path.module}/config/.rendered/cloud-init.yaml"
  content         = local.cloud_init_rendered
  file_permission = "0600"
}

resource "multipass_instance" "staging" {
  name           = "staging"
  cpus           = 2
  memory         = "8G"
  disk           = "40G"
  image          = var.ubuntu_img_path
  cloudinit_file = local_file.cloud_init.filename
  depends_on     = [local_file.cloud_init]
}

output "vm_ip" {
  value = multipass_instance.staging.ipv4
}
