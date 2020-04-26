# My Packer Templates

[Packer](http://packer.io) templates for Linux boxes. v0 of this templates are
from https://bitbucket.org/ariya/packer-vagrant-linux

-   CentOS 6.4 (Minimal) 64-bit

-   CentOS 6.5 (Minimal) 64-bit

-   CentOS 7.3 (Minimal) 64-bit

-   Ubuntu 12.04 LTS (Precise Pangolin) 64-bit

-   Ubuntu Desktop 19.04 64-bit

Use the box (generated in `build` subdirectory) with
[Vagrant](http://vagrantup.com) and [VirtualBox](http://virtualbox.org).

 

## How to run packer & generate a box

 
Install [Packer](www.packer.io)

Run: ```packer build \<json\>```

Afterwards if you want you can do:

```vagrant box add build/name of your box --name another-name```

## (Optional) Running ansible to configure OS inside packer
If you are running the ansible provisioner, make sure to clone your ansible repository inside this one before continuing or make the necessary adjustments to accomodate your ansible roles. Check the example in **ubuntu-desktop.json


## Using the Box
Go to main programming folder

Run ```vagrant init <your box name>```

-

Known Errors with Packer
------------------------

 

**Curl - Port is too large**

To solve this rename your boot_command to a smaller string

 

**When Packer is typing the boot_command it duplicates or remove characters**

This is a known issue due to host CPU load. There’s no fix. You need just run
again and again or correct the command manually:
https://github.com/hashicorp/packer/issues/1796
