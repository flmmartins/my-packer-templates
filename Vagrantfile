Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"

  # Enable internet access
  config.vm.network "public_network"

  config.vm.synced_folder ".", "/vagrant", type: "nfs"

  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
    vb.customize ['setextradata', :id, 'GUI/ScaleFactor', '1.25']
    vb.memory = "3072"
    vb.cpus = "3"
  end
end
