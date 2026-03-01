Vagrant.configure("2") do |config|
  config.vm.box     = "${vm_name}"
  config.vm.box_url = "${box_output}"
  config.vm.provider :qemu do |qemu|
    qemu.memory     = "${memory_mb}M"
    qemu.cpus       = ${cpu_cores}
    qemu.arch       = "x86_64"
    qemu.machine    = "${machine_type}"
    qemu.net_device = "virtio-net-pci"
    qemu.cpu = "max"
  end
  config.ssh.private_key_path = "${private_key_path}"
  config.ssh.forward_agent    = true
  config.vm.network "public_network"
  config.vm.synced_folder ".", "/vagrant", type: "rsync"
end