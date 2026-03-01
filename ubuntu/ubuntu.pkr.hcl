packer {
  required_plugins {
    qemu = {
      version = "~> 1"
      source  = "github.com/hashicorp/qemu"
    }

    vagrant = {
      version = "~> 1"
      source = "github.com/hashicorp/vagrant"
    }
  }
}

locals {
  # Output directory needs to clean on every build, so had to generate one for each source
  vm_name_with_format = "${var.vm_name}.${var.qemu_machine_format}"
  output_directory   = "builds"
  packer_private_key = "${path.root}/${var.packer_ssh_keypair_path}"
  packer_public_key  = file("${var.packer_ssh_keypair_path}.pub")
  cd_label     = "cidata"
  cd_content   = {
    "meta-data" = "",
    "user-data" = templatefile("user-data.pkrtpl.hcl", { 
      packer_ssh_user       = var.machine_user
      packer_ssh_public_key = local.packer_public_key
      human_ssh_public_key  = file("${var.human_ssh_key_path}.pub")
      machine_init_password = var.machine_init_pwd
    })
  }

  rendered_vagrantfile = "Vagrantfile"
  vagrant_box_output   = "${local.output_directory}/${var.vm_name}.box"
  vagrantfile_content = templatefile("vagrantfile.pkrtpl.hcl", {
    vm_name             = var.vm_name
    memory_mb           = var.memory_mb
    cpu_cores           = var.cpu_cores
    machine_type        = var.qemu_machine_type
    private_key_path    = var.human_ssh_key_path
    box_output          = local.vagrant_box_output
  })

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
  vm_name                   = local.vm_name_with_format
  iso_checksum              = "file:${var.iso_checksum_file_url}"
  iso_url                   = var.iso_url
  disk_size                 = "${var.disk_size_mb}M"
  disk_compression          = true
  disk_interface            = "virtio"
  format                    = var.qemu_machine_format
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
  machine_type              = var.qemu_machine_type
  efi_boot                  = true
  efi_firmware_code         = var.qemu_efi_firmware_code
  efi_firmware_vars         = var.qemu_efi_firmware_vars
  # SSH Forwarding
  qemuargs = [
    ["-netdev", "user,id=net0,hostfwd=tcp::${var.ssh_port}-:22"],
    ["-device", "virtio-net-pci,netdev=net0"]
  ]
}

build {
  sources = ["source.qemu.ubuntu"]

  # Delete packer key and change password on next login
  provisioner "shell" {
    inline = [
      "grep -v -F -x '${local.packer_public_key}' ~/.ssh/authorized_keys > /tmp/ak.tmp",
      "mv /tmp/ak.tmp ~/.ssh/authorized_keys",
      "sudo passwd --expire ${var.machine_user}"
    ]
  }

  # Render vagrantfile template
  post-processor "shell-local" {
    inline = ["echo '${local.vagrantfile_content}' > ${local.rendered_vagrantfile}"]
  } 

  # Convert from qcow2 to raw because I need in raw as well
  post-processor "shell-local" {
    inline = [
      "qemu-img convert -f qcow2 -O raw ${local.output_directory}/qemu/${local.vm_name_with_format} ${local.output_directory}/qemu/${var.vm_name}.raw",
      "echo 'Raw image created: ${local.output_directory}/qemu/${var.vm_name}.raw'"
    ]
  }

  # Qcow is the acccepted format for vagrant box qemu
  post-processor "vagrant" {
    output                         = local.vagrant_box_output
    vagrantfile_template           = local.rendered_vagrantfile
    vagrantfile_template_generated = true
    keep_input_artifact            = true
  }
}