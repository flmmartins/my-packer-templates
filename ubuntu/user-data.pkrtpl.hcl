#cloud-config
autoinstall:
  version: 1
  timezone: Europe/Amsterdam
  network:
    network:
      version: 2
      ethernets:
        eth0:
          dhcp4: true
          match:
            name: "en*"
  ssh:
    install-server: true
    allow-pw: false
  user-data:
    runcmd:
      - systemctl enable ssh
      - systemctl start ssh
    users:
      - name: ${packer_ssh_user}
        passwd: ${machine_pwd_hashed}
        groups: [adm, sudo]
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - "${human_ssh_public_key}"
          - "${packer_ssh_public_key}"
        lock-passwd: false
        shell: /bin/bash
      - name: vagrant
        groups: [adm, sudo]
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - "${human_ssh_public_key}"
        lock-passwd: true
        shell: /bin/bash