# --- Render cloud-init config file --- #
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


# --- Provision VM --- #
resource "multipass_instance" "staging" {
  name           = "staging"
  cpus           = 4
  memory         = "10G"
  disk           = "100G"
  image          = var.ubuntu_img_path
  cloudinit_file = local_file.cloud_init.filename
  depends_on     = [local_file.cloud_init]
}
