variable "vm_name" {
  type    = string
  default = "ubuntu-server"
}

variable "iso_checksum_file_url" {
  type    = string
  default = "https://releases.ubuntu.com/24.04.4/SHA256SUMS"
}

variable "iso_url" {
  default = "https://releases.ubuntu.com/24.04.4/ubuntu-24.04.4-live-server-amd64.iso"
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
  default     = "root"
  description = "Packer will use this user and auto generated ssh_key which will be erased afterwards"
}

variable "machine_pwd_hashed" {
  type        = string
  description = "This password is a fallback and a new password will be prompted on first login"
}

variable "human_ssh_key_path" {
  description = "Human SSH key to be installed in the VM that can assume root user. The public key will be inside the machine and the private will be used to instruct vagrant which key to use when doing vagrant up"
  default     = "~/.ssh/id_ed25519"
}

variable "packer_ssh_keypair_path" {
  default     = "packer_key"
  description = "SSH Private and Public Key Pair used by packer. It assumes both keys exist packer_key and packer_key.pub inside ubuntu repository folder"
}

variable "ssh_timeout" {
  default     = "60m"
  description = "Timeout waiting for packer to ssh"
}

variable "ssh_port" {
  default = 2222
}

variable "boot_wait" {
  type        = string
  description = "Wait for machine boot after before installing"
  default     = "3s"
}

###############################
# PACKER HOST CONFIGURATION
###############################
# This configuration depends on where you are using packer cli

variable "qemu_efi_firmware_code" {
  description = "Use this to enable UEFI boot. Defaults to mac file path but if in linux use /usr/share/OVMF/OVMF_CODE.fd after instal it with sudo apt install -y packer ovmf"
  default     = "/opt/homebrew/share/qemu/edk2-x86_64-code.fd"
}

variable "qemu_efi_firmware_vars" {
  description = "Use this to enable UEFI boot. Defaults to mac file path but if in linux use /usr/share/OVMF/OVMF_VARS.fd after instal it with sudo apt install -y packer ovmf"
  default     = "/opt/homebrew/share/qemu/edk2-i386-vars.fd"
}

variable "qemu_accelerator" {
  description = "For linux use kvm to build images faster. For mac you can use however hvf only supports x86_64 on Intel Macs. If you're on Apple Silicon (M1/M2/M3) building an amd64 Ubuntu image, you can't use hvf for x86 emulation"
  default     = "tcg"
}

variable "qemu_machine_type" {
  description = "Qemu machine type to emulate. It can be pc (legacy), q35 for UEFI/OVMF and virt for ARM"
  default     = "q35"
}

variable "qemu_machine_format" {
  description = "Output machine format. Valid values are raw, qcow2 (best for qemu), vmdk, vdi"
  default     = "qcow2"
}