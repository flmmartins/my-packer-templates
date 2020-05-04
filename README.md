
Generate [Vagrant Boxes](http://vagrantup.com) in [VirtualBox](http://virtualbox.org) using [Packer](http://packer.io)

There's also a [CentOS Box](http://vagrantup.com) in HyperV 


# List of Boxes (images) you can generate

Boxes are generated by json files. Below is a description.
 
## Ubuntu Boxes

All Ubuntu run on top of VirtualBox

* Select ubuntu-desktop for building Ubuntu Desktop 20.04 64-bit

* Select ubuntu-server for building Ubuntu Desktop 20.04 64-bit headless


**Optional** 
You can use the ubuntu jsons to build any ubuntu desktop or server with the version of your choosing. Edit the variables inside the json according to what you want. If not, the version indicated will be installed.

## CentOs Boxes

* CentOS 8 64 bit on VirtualBox

**Optional** 
You can use the json on Virtualbox to build any CentOS with the version of your choosing. Edit the variables inside the json according to what you want. If not, the version indicated will be installed.


* CentOS 7 64-bit on HyperV.

The CentOs Hyper V builds a CentOS on top of the Windows virtualization software HyperV in Windows 10 Ultimate.

# How generate a box
 
 
Install [Packer](www.packer.io), [Vagrant](http://vagrantup.com) and [VirtualBox](http://virtualbox.org).

You can edit any variables in the json variable with the linux of your choosing

Run: ```packer build \<json\>```

Afterwards if you want you can do:

```vagrant box add ./build/name-of-the-box --name your-nickname```

Ex:
vagrant box add ./build/ubuntu-19.04-desktop-amd64-virtualbox.box --name my-ubuntu

# Using the Box
Go to main programming folder

Run ```vagrant init <your box name>```

This will generate a Vagrantfile based on the Vagranfile template.

# Box configuration details

## VM resources & Vagrantfile

The boxes resources will be configured by Vagrantfile templates for use but you can overwrite it using your own Vagrantfile. The only thing that the json does is to set the disk size.

## OS configuration files

The unattended configuration files that will setup the box are in the http folder. They automate the OS installation screens

## (WIP not ready) Runing ansible to configure OS

After you install the OS, ansible can be used to fully configure your OS

If you are running the ansible provisioner, make sure to clone your ansible repository inside this one before continuing or make the necessary adjustments to accomodate your ansible roles. Check the variables inside the json files


# Known Errors with Packer
 

**Curl - Port is too large**

To solve this rename your boot_command to a smaller string

 

**When Packer is typing the boot_command it duplicates or remove characters**

This is a known issue due to host CPU load. There’s no fix. You need just run
again and again or correct the command manually:
https://github.com/hashicorp/packer/issues/1796
