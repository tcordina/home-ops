provider "proxmox" {
  pm_api_url          = "https://${var.pve_ip}:8006/api2/json"
  pm_api_token_id     = "terraform-prov@pve!mytoken"
  pm_api_token_secret = var.proxmox_api_token
  pm_tls_insecure     = true
  pm_debug            = true
}

terraform {
  required_version = ">=1.0"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc08"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}