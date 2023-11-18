variable "vm_name" {
  default = "ubuntu-server"
}

variable "iso_checksum_file_url" {
  default = "https://releases.ubuntu.com/22.04.3/SHA256SUMS"
}

variable "iso_url" {
  default = "https://releases.ubuntu.com/22.04.3/ubuntu-22.04.3-live-server-amd64.iso"
}

variable "disk_size_mb" {
  default = 32000
}

variable "cpu_cores" {
  default = 2
}

variable "memory_mb" {
  default = 2048
}

variable "machine_user" {
  default     = "admin"
  description = "Packer will use this user and auto generated ssh_key which will be erased afterwards"
}

variable "machine_init_pwd" {
  #packerubuntu
  default = "$6$xyz$74AlwKA3Z5n2L6ujMzm/zQXHCluA4SRc2mBfO2/O5uUc2yM2n2tnbBMi/IVRLJuKwfjrLZjAT7agVfiK7arSy/"
  description = "This password is a fallback and a new password should be set on first login"
}

variable "human_ssh_key_path" {
  #default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK5JiluJIXtH4tDDC9YwoH8VTxTpKTVVklwPTUeqZDCU flmmartins"
  default = "~/.ssh/id_ed25519"
}

variable "ssh_timeout" {
  default     = "60m"
  description = "Timeout waiting for packer to ssh"
}

variable "boot_wait" {
  default = "3s"
}

variable "vagrant_template_file_path" {
  default = "vagrant_templates/virtualbox/Vagrantfile-linux-server.template"
}

variable "vagrant_provider" {
  default     = "virtualbox"
  description = "For which platform to build the vagrant box"
}