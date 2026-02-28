packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }

    virtualbox = {
      version = "~> 1"
      source  = "github.com/hashicorp/virtualbox"
    }

    vagrant = {
      version = "~> 1"
      source = "github.com/hashicorp/vagrant"
    }
  }
}

locals {
  iso_checksum = "file:${var.iso_checksum_file_url}"
  
  # Output directory needs to clean on every build, so had to generate one for each source
  output_directory   = "builds"
  virtualbox_vm_name = "virtualbox_${var.vm_name}"
  qemu_vm_name       = "qemu_${var.vm_name}"
  packer_private_key = "${path.root}/${var.packer_ssh_keypair_path}"
  packer_public_key  = file("${var.packer_ssh_keypair_path}.pub")
  cd_label     = "cidata"
  cd_content   = {
    "meta-data" = "",
    "user-data" = templatefile("user-data.pkrtpl.hcl", { 
      packer_ssh_user       = var.machine_user
      packer_ssh_public_key = local.packer_public_key
      human_ssh_public_key  = file("${var.human_ssh_pub_key_path}")
      machine_init_password = var.machine_init_pwd
    })
  }

  boot_command       = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall",
    "<f10><wait>"
  ]
}

source "qemu" "ubuntu" {
  vm_name                   = var.vm_name
  iso_checksum              = local.iso_checksum
  iso_url                   = var.iso_url
  disk_size                 = "${var.disk_size_mb}M"
  disk_compression          = true
  disk_interface            = "virtio"
  format                    = "raw"
  net_device                = "virtio-net"
  cpus                      = var.cpu_cores
  memory                    = var.memory_mb
  ssh_username              = var.machine_user
  ssh_private_key_file      = local.packer_private_key
  ssh_clear_authorized_keys = true # Try to clear packer ssh keys after install
  ssh_timeout               = var.ssh_timeout
  host_port_min             = var.ssh_port
  host_port_max             = var.ssh_port
  ssh_port                  = var.ssh_port
  cd_label                  = local.cd_label
  cd_content                = local.cd_content
  headless                  = true # false crashes qemu
  output_directory          = "${local.output_directory}/qemu"
  vnc_bind_address          = "0.0.0.0"
  vnc_port_min              = 5940
  vnc_port_max              = 5940
  boot_command              = local.boot_command
  boot_wait                 = var.boot_wait
  shutdown_command          = "echo 'packer' | sudo -S shutdown -P now"
  accelerator               = var.qemu_accelerator
  machine_type              = "q35"
  efi_boot                  = true
  efi_firmware_code         = var.qemu_efi_firmware_code
  efi_firmware_vars         = var.qemu_efi_firmware_vars
  # SSH Forwarding
  qemuargs = [
    ["-netdev", "user,id=net0,hostfwd=tcp::${var.ssh_port}-:22"],
    ["-device", "virtio-net-pci,netdev=net0"]
  ]
}

source "virtualbox-iso" "ubuntu" {
  vm_name                   = var.vm_name
  guest_os_type             = "Ubuntu_64"
  iso_url                   = var.iso_url
  iso_checksum              = local.iso_checksum
  disk_size                 = var.disk_size_mb
  cpus                      = var.cpu_cores
  memory                    = var.memory_mb
  ssh_username              = var.machine_user
  ssh_private_key_file      = local.packer_private_key
  ssh_clear_authorized_keys = true
  ssh_timeout               = var.ssh_timeout
  headless                  = false
  output_directory          = "${local.output_directory}/virtualbox-iso"
  cd_content                = local.cd_content
  cd_label                  = local.cd_label
  boot_command              = local.boot_command
  boot_wait                 = var.boot_wait
  shutdown_command          = "echo 'packer' | sudo -S shutdown -P now"
  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--clipboard", "bidirectional"]
  ]
}

build {
  sources = [
    "source.qemu.ubuntu",
    "source.virtualbox-iso.ubuntu"
  ]

  # Delete packer key and change password on next login
  provisioner "shell" {
    inline = [
      "grep -v -F -x '${local.packer_public_key}' ~/.ssh/authorized_keys > /tmp/ak.tmp",
      "mv /tmp/ak.tmp ~/.ssh/authorized_keys",
      "sudo passwd --expire ${var.machine_user}"
    ]
  }

  # Using post processor for qemu produces a libvirt which is only supported by linux
  post-processor "vagrant" {
    only                           = ["virtualbox-iso.ubuntu"]
    output                         = "${local.output_directory}/{{.Provider}}_${var.vm_name}.box"
    vagrantfile_template           = "vagrantfile.template"
    keep_input_artifact            = true
  }
}