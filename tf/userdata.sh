#!/usr/bin/bash

sudo zypper refresh
sudo zypper install -y git bind-utils mlocate
# net-tools-deprecated

sudo echo "alias l='ls -latFrh'" >> /home/ec2-user/.bashrc
sudo echo "alias vi=vim"         >> /home/ec2-user/.bashrc
sudo echo "set background=dark"  >> /home/ec2-user/.vimrc
sudo echo "syntax on"            >> /home/ec2-user/.vimrc
sudo echo "alias l='ls -latFrh'" >> /root/.bashrc
sudo echo "alias vi=vim"         >> /root/.bashrc
sudo echo "set background=dark"  >> /root/.vimrc
sudo echo "syntax on"            >> /root/.vimrc

#sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config
#sudo setenforce 0

