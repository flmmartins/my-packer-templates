#!/bin/bash -eux

export DEBIAN_FRONTEND="noninteractive"

# Somehow although the iso is eoan apt from there still point to disco
if [ $(lsb_release -rs) == "19.04" ]; then
  sed -i 's/disco/eoan/g' /etc/apt/sources.list
fi

# Update the box
apt-get update -qq > /dev/null
apt-get dist-upgrade -qq -y > /dev/null
