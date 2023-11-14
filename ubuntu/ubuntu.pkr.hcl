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

      sshkey = {
        version = "~> 1"
        source = "github.com/ivoronin/sshkey"
      }

      ansible = {
        source  = "github.com/hashicorp/ansible"
        version = "~> 1"
      }
    }
}

data "sshkey" "install" {
  name = "packer_ssh_key"
}

locals {
  iso_checksum = "file:${var.iso_checksum_file_url}"
  cd_label     = "cidata"
  cd_content   = {
    "meta-data" = "",
    "user-data" = templatefile("user-data", { 
      packer_ssh_user       = var.machine_credentials["user"]
      packer_ssh_key        = data.sshkey.install.public_key
      human_ssh_public_key  = var.machine_credentials["ssh_key"]
      machine_init_password = var.machine_credentials["init_pwd"]
    })
  }
  # Output directory needs to clean on every build, so had to generate one for each source
  output_directory   = "builds"
  # Names have to be different in case of concurrent builds. Cannot use {{ }} variables
  virtualbox_vm_name = "virtualbox_${var.vm_name}"
  qemu_vm_name       = "qemu_${var.vm_name}"
  boot_command       = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "autoinstall",
    "<f10><wait>"
  ]
}

source "qemu" "install" {
  vm_name                   = local.qemu_vm_name
  iso_checksum              = local.iso_checksum
  iso_url                   = var.iso_url
  disk_size                 = "${var.disk_size_mb}M"
  disk_compression          = true
  disk_interface            = "virtio"
  format                    = "qcow2"
  net_device                = "virtio-net"
  cpus                      = var.cpu_cores
  memory                    = var.memory_mb
  ssh_username              = var.machine_credentials["user"]
  ssh_private_key_file      = data.sshkey.install.private_key_path
  ssh_clear_authorized_keys = true # Clear packeys after install
  ssh_timeout               = var.ssh_timeout
  cd_label                  = local.cd_label
  cd_content                = local.cd_content
  headless                  = true # false crashes qemu
  output_directory          = "${local.output_directory}/${local.qemu_vm_name}"
  vnc_bind_address          = "0.0.0.0"
  vnc_port_min              = 5940
  vnc_port_max              = 5940
  boot_command              = local.boot_command
  boot_wait                 = var.boot_wait
  shutdown_command          = "echo 'packer' | sudo -S shutdown -P now"
}

# Doesn't work for Mac M1, so we skip it
source "virtualbox-iso" "install" {
  vm_name                   = local.virtualbox_vm_name
  guest_os_type             = "Ubuntu_64"
  iso_url                   = var.iso_url
  iso_checksum              = local.iso_checksum
  disk_size                 = var.disk_size_mb
  cpus                      = var.cpu_cores
  memory                    = var.memory_mb
  ssh_username              = var.machine_credentials["user"]
  ssh_private_key_file      = data.sshkey.install.private_key_path
  ssh_clear_authorized_keys = true
  ssh_timeout               = var.ssh_timeout
  headless                  = false
  output_directory          = "${local.output_directory}/${local.virtualbox_vm_name}"
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
    "source.qemu.install",
    "source.virtualbox-iso.install"
  ]

  provisioner "shell" {
    inline = [
      "echo Removing packer ssh key",
      "sed -i '/.*packer_ssh_key$/d' ~/.ssh/authorized_keys",
    ]
  }

  post-processor "checksum" {
    checksum_types = ["md5", "sha256"]
    output = "{{.BuilderType}}_${var.vm_name}_{{.ChecksumType}}.checksum"
  }

  post-processor "compress" {
    output = "{{.BuilderType}}_${var.vm_name}.tar.gz"
  }

  post-processor "vagrant" {
    output               = "${var.vm_name}.box"
    vagrantfile_template = var.vagrant_template_file_path
    provider             = var.vagrant_provider
  }
}

