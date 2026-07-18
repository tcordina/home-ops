# --- Ignition --- #
data "ct_config" "ignition" {
  content = templatefile("${path.module}/config/butane.yaml.tpl", {
    ssh_public_key = var.ssh_public_key
    vm_ip          = var.vm_ip
    vm_gateway     = var.vm_gateway
    vm_dns         = var.vm_dns
  })
  strict = true
}

resource "libvirt_ignition" "staging" {
  name    = "staging-ignition"
  content = data.ct_config.ignition.rendered
}

# --- Provision VM --- #
resource "libvirt_domain" "staging" {
  name    = "staging"
  type    = "kvm"
  vcpu        = 4
  memory      = 10240
  memory_unit = "MiB"
  running     = false

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    firmware     = "efi"
  }

  cpu = {
    mode = "host-passthrough"
  }

  features = {
    acpi = true
  }

  # Passe l'ignition config à FCOS via QEMU firmware config
  qemu_commandline = {
    args = [
      { value = "-fw_cfg" },
      { value = "name=opt/com.coreos/config,file=${libvirt_ignition.staging.path}" },
    ]
  }

  devices = {
    disks = [
      # /dev/vda — système FCOS
      {
        source = {
          volume = {
            pool   = libvirt_pool.staging.name
            volume = libvirt_volume.staging_system.name
          }
        }
        driver = {
          name = "qemu"
          type = "qcow2"
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      # /dev/vdb — données LVM thin pool (TopoLVM / Volsync)
      {
        source = {
          volume = {
            pool   = libvirt_pool.staging.name
            volume = libvirt_volume.staging_data.name
          }
        }
        driver = {
          name = "qemu"
          type = "qcow2"
        }
        target = {
          dev = "vdb"
          bus = "virtio"
        }
      },
    ]

    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = libvirt_network.staging.name
          }
        }
      },
    ]
    # serial and console bugged with provider. `sudo virsh edit staging` and set this inside <devices>  
    # <serial type='pty'>
    #   <target type='isa-serial' port='0'>
    #     <model name='isa-serial'/>
    #   </target>
    # </serial>
    # <console type='pty'>
    #   <target type='serial' port='0'/>
    # </console>

  }

  lifecycle {
    ignore_changes = [devices]
  }
}
