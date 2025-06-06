#!/usr/bin/bash

zypper refresh
zypper --non-interactive install -y git bind-utils mlocate lvm2 jq nfs-client cryptsetup open-iscsi
#zypper install -y git bind-utils mlocate lvm2 jq nfs-client cryptsetup open-iscsi

echo "alias l='ls -latFrh'" >> /home/ec2-user/.bashrc
echo "alias vi=vim"         >> /home/ec2-user/.bashrc
echo "set background=dark"  >> /home/ec2-user/.vimrc
echo "syntax on"            >> /home/ec2-user/.vimrc
echo "alias l='ls -latFrh'" >> /root/.bashrc
echo "alias vi=vim"         >> /root/.bashrc
echo "set background=dark"  >> /root/.vimrc
echo "syntax on"            >> /root/.vimrc

systemctl enable iscsid --now

# Tuning
# Environment: promtail on amd64 EC2
echo "fs.inotify.max_user_instances = 1024" | tee -a /etc/sysctl.conf
sysctl -p
