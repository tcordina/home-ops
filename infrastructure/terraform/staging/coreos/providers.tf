terraform {
  required_version = ">=1.0"

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.9.8"
    }
    ct = {
      source  = "poseidon/ct"
      version = "0.14.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.9.0"
    }
  }
}

provider "libvirt" {
  uri = var.libvirt_uri
}
