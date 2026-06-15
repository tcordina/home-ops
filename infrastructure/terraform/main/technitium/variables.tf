variable "pve_ip" {
  type      = string
}

variable "proxmox_api_token" {
  sensitive = true
  type      = string
}