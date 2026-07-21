variable "pve_ip" {
  type      = string
}

variable "proxmox_api_token" {
  sensitive = true
  type      = string
}

variable "talos_iso_file_name" {
  type      = string
}