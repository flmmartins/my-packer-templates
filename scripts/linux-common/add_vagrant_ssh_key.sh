#!/bin/bash -eux

date > /etc/vagrant_box_build_time

SSH_USER=${SSH_USERNAME:-vagrant}
SSH_USER_HOME=${SSH_USER_HOME:-/home/${SSH_USER}}


# Set up sudo
echo "==> Giving ${SSH_USER} sudo powers"
echo "${SSH_USER}        ALL=(ALL)       NOPASSWD: ALL" > /etc/sudoers.d/vagrant

echo "==> Installing vagrant key"
if [ ! -d $SSH_USER_HOME/.ssh ]; then
  mkdir $SSH_USER_HOME/.ssh
fi
chmod 700 $SSH_USER_HOME/.ssh
wget --no-check-certificate -O authorized_keys 'https://github.com/mitchellh/vagrant/raw/master/keys/vagrant.pub'
mv authorized_keys $SSH_USER_HOME/.ssh
chmod 600 $SSH_USER_HOME/.ssh/authorized_keys
chown -R $SSH_USER:$SSH_USER $SSH_USER_HOME/.ssh