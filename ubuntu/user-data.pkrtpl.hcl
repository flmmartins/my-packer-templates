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
      lock_passwd: false
      shell: /bin/bash
    - name: vagrant
      groups: [adm, sudo]
      sudo: ALL=(ALL) NOPASSWD:ALL
      ssh_authorized_keys:
      - "${human_ssh_public_key}"
      lock_passwd: true
      shell: /bin/bash
  storage:
    config:
    # Disk config
    - type: disk
      id: disk-vda
      ptable: gpt
      match:
        size: largest
      preserve: false
      name: ''
      grub_device: true
      wipe: superblock-recursive


    # Bios Partition (required)
    - type: partition
      id: partition-0
      device: disk-vda
      size: 4194304
      wipe: superblock
      flag: bios_grub
      number: 1
      preserve: false
      grub_device: false

    # EFI Partition - will be set to primary boot dev due to early command
    - type: partition
      id: partition-1
      device: disk-vda
      size: 111149056
      wipe: superblock
      flag: boot
      number: 2
      preserve: false
      grub_device: UEFI

    - type: format
      id: format-0
      volume: partition-1
      fstype: fat32
      preserve: false

    # Create Boot partition
    - type: partition
      id: partition-2
      device: disk-vda
      size: 5GB
      wipe: superblock
      number: 3
      preserve: false
      grub_device: false

    - type: format
      id: format-1
      volume: partition-2
      fstype: ext4
      preserve: false

    # LVM Partition
    - type: partition
      id: partition-3
      device: disk-vda
      size: -1
      wipe: superblock
      number: 4
      preserve: false
      grub_device: false

    # Encryption
    #- type: dm_crypt
    #  id: dm_crypt-0
    #  volume: partition-3
    #  preserve: false
    #  key: 'ubuntu'

    - type: lvm_volgroup
      id: lvm_volgroup-0
      devices:
      - partition-3
      #- dm_crypt-0
      preserve: false
      name: ubuntu-vg

    - type: lvm_partition
      id: lvm_partition-0
      volgroup: lvm_volgroup-0
      size: -1
      preserve: false
      wipe: superblock
      name: ubuntu-lv

    - type: format
      id: format-2
      volume: lvm_partition-0
      fstype: btrfs
      preserve: false

    - type: mount
      id: mount-0
      device: format-0
      path: /boot/efi

    - type: mount
      id: mount-1
      device: format-1
      path: /boot

    - type: mount
      id: mount-2
      device: format-2
      path: /
  # If there's an EFI on packer, it will boot from it otherwise it will use legacy boot
  early-commands:
    - |
      if [ -e "/sys/firmware/efi" ]; then
        sed -i -e "s/grub_device: UEFI/grub_device: true/" /autoinstall.yaml
      else
        sed -i -e "s/grub_device: UEFI/grub_device: false/" /autoinstall.yaml
      fi
  # If EFI the below solves: https://github.com/hashicorp/packer-plugin-qemu/issues/66#issuecomment-1466049817
  late-commands:
    - |
      if [ -d /sys/firmware/efi ]; then
        apt-get install -y efibootmgr
        efibootmgr -o $(efibootmgr | perl -n -e '/Boot(.+)\* ubuntu/ && print $1')
      fi