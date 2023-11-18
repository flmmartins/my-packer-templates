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
    }
}

data "sshkey" "install" {
  name = "packer_ssh_key"
}

locals {
  iso_checksum = "file:${var.iso_checksum_file_url}"
  
  # Output directory needs to clean on every build, so had to generate one for each source
  output_directory   = "builds"
  virtualbox_vm_name = "virtualbox_${var.vm_name}"
  qemu_vm_name       = "qemu_${var.vm_name}"

  cd_label     = "cidata"
  cd_content   = {
    "meta-data" = "",
    "user-data" = templatefile("user-data.pkrtpl.hcl", { 
      packer_ssh_user       = var.machine_user
      packer_ssh_key        = data.sshkey.install.public_key
      human_ssh_public_key  = file("${var.human_ssh_key_path}.pub")
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
  format                    = "qcow2"
  net_device                = "virtio-net"
  cpus                      = var.cpu_cores
  memory                    = var.memory_mb
  ssh_username              = var.machine_user
  ssh_private_key_file      = data.sshkey.install.private_key_path
  ssh_clear_authorized_keys = true # Clear packeys after install
  ssh_timeout               = var.ssh_timeout
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
  ssh_private_key_file      = data.sshkey.install.private_key_path
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

  provisioner "shell" {
    inline = [
      "echo Removing packer ssh key",
      "sed -i '/.*packer_ssh_key$/d' ~/.ssh/authorized_keys",
    ]
  }

  post-processor "vagrant" {
    output                         = "${local.output_directory}/{{.BuilderType}}/{{.Provider}}_${var.vm_name}.box"
    vagrantfile_template           = "vagrantfile.${var.vagrant_provider}.template"
    provider_override              = var.vagrant_provider
    keep_input_artifact            = true
  }
}