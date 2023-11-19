#cloud-config
autoinstall:
  version: 1
  timezone: Europe/Amsterdam
  network:
    network:
      version: 2
      renderer: networkd
      ethernets:
        myinterface:
          match:
            name: en*
          dhcp4: yes
  ssh:
    install-server: true
    allow-pw: true
  user-data:
    users:
    - name: ${packer_ssh_user}
      passwd: ${machine_init_password}
      groups: [adm, sudo]
      sudo: ALL=(ALL) NOPASSWD:ALL
      ssh_authorized_keys:
      - "${human_ssh_public_key}"
      - "${packer_ssh_key}"
      lock-passwd: false
      shell: /bin/bash
    - name: vagrant
      groups: [adm, sudo]
      sudo: ALL=(ALL) NOPASSWD:ALL
      ssh_authorized_keys:
      - "${human_ssh_public_key}"
      lock-passwd: true
      shell: /bin/bash
