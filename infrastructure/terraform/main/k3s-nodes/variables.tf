variable "pve_ip" {
  type      = string
}

variable "pve2_ip" {
  type      = string
}

variable "proxmox_api_token" {
  sensitive = true
  type      = string
}

variable "ssh_private_key" {
  sensitive = true
  type      = string
}