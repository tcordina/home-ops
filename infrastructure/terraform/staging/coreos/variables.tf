variable "ssh_public_key" {
  type = string
}

variable "fcos_image_path" {
  description = "file:// URL vers l'image FCOS qcow2 (ex: file:///home/user/fcos.qcow2)"
  type        = string
}

variable "libvirt_uri" {
  type    = string
  default = "qemu:///system"
}

variable "libvirt_pool" {
  description = "Nom du storage pool libvirt à créer"
  type        = string
  default     = "staging"
}

variable "vm_ip" {
  description = "IP statique de la VM (dans le subnet 192.168.200.0/24)"
  type        = string
  default     = "192.168.200.10"
}

variable "vm_gateway" {
  type    = string
  default = "192.168.200.1"
}

variable "vm_dns" {
  description = "Serveurs DNS pour NetworkManager (séparés par ;)"
  type        = string
  default     = "192.168.200.1;1.1.1.1;"
}
