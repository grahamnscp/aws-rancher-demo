#!/usr/bin/bash

zypper refresh
zypper install -y git bind-utils mlocate lvm2 jq nfs-client cryptsetup open-iscsi

echo "alias l='ls -latFrh'" >> /home/ec2-user/.bashrc
echo "alias vi=vim"         >> /home/ec2-user/.bashrc
echo "set background=dark"  >> /home/ec2-user/.vimrc
echo "syntax on"            >> /home/ec2-user/.vimrc
echo "alias l='ls -latFrh'" >> /root/.bashrc
echo "alias vi=vim"         >> /root/.bashrc
echo "set background=dark"  >> /root/.vimrc
echo "syntax on"            >> /root/.vimrc

systemctl enable iscsid --now

