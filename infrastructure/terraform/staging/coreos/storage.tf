# --- Storage pool --- #
resource "libvirt_pool" "staging" {
  name = var.libvirt_pool
  type = "dir"

  target = {
    path = "/var/lib/libvirt/images/${var.libvirt_pool}"
  }
}

# --- Volumes --- #
resource "libvirt_volume" "fcos_base" {
  name = "fcos-base.qcow2"
  pool = libvirt_pool.staging.name

  create = {
    content = {
      url = var.fcos_image_path
    }
  }

  target = {
    format = {
      type = "qcow2"
    }
  }

  depends_on = [libvirt_pool.staging]
}

resource "libvirt_volume" "staging_system" {
  name     = "staging-system.qcow2"
  pool     = libvirt_pool.staging.name
  capacity = 32212254720 # 30 GB

  backing_store = {
    path = libvirt_volume.fcos_base.path
    format = {
      type = "qcow2"
    }
  }

  target = {
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_volume" "staging_data" {
  name     = "staging-data.qcow2"
  pool     = libvirt_pool.staging.name
  capacity = 75161927680 # 70 GB — LVM thin pool

  target = {
    format = {
      type = "qcow2"
    }
  }
}
