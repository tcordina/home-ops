resource "libvirt_network" "staging" {
  name      = "staging-net"
  autostart = true

  forward = {
    mode = "nat"
  }

  ips = [
    {
      address = var.vm_gateway
      prefix  = 24
    }
  ]
}
