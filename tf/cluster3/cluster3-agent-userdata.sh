#!/usr/bin/bash

echo "==========> Started userdata script.."

# user shell
echo "alias l='ls -latFrh'" >> /home/ec2-user/.bashrc
echo "alias vi=vim"         >> /home/ec2-user/.bashrc
echo "set background=dark"  >> /home/ec2-user/.vimrc
echo "syntax on"            >> /home/ec2-user/.vimrc
echo "alias l='ls -latFrh'" >> /root/.bashrc
echo "alias vi=vim"         >> /root/.bashrc
echo "set background=dark"  >> /root/.vimrc
echo "syntax on"            >> /root/.vimrc

# repos and packages
zypper refresh
zypper --non-interactive install -y git bind-utils mlocate lvm2 jq nfs-client cryptsetup open-iscsi

# enable for longhorn
systemctl enable iscsid --now

# nvidia
zypper addrepo --refresh https://download.nvidia.com/suse/sle15sp6/ nvidia-sle15sp6-main
zypper --gpg-auto-import-keys refresh
zypper --non-interactive install --auto-agree-with-licenses nvidia-open-driver-G06-signed-kmp=550.144.03 nvidia-compute-utils-G06=550.144.03

updatedb

# create a systemd config script for first boot
mkdir -p /root/bin/
cat > /root/bin/suse-fb-config.sh << _EOFSCRIPT_
#!/bin/bash
touch /root/.suse-fb-config.started

# after reboot
cat /proc/driver/nvidia/version
ln -s /sbin/ldconfig /sbin/ldconfig.real

zypper --non-interactive install -y git bind-utils mlocate lvm2 jq nfs-client cryptsetup open-iscsi

# enable for longhorn
systemctl enable iscsid --now

#
touch /root/.suse-fb-config.ran

echo "suse-fb-config.sh done"
exit 0
_EOFSCRIPT_
chmod 0755 /root/bin/suse-fb-config.sh

cat <<- _EOFCONFIG_ > /etc/systemd/system/suse-fb-config.service
[Unit]
Description=SUSE First Boot Config Service
Wants=network-online.target
After=network.target network-online.target
ConditionPathExists=/root/bin/suse-fb-config.sh
ConditionPathExists=!/root/.suse-fb-config.ran

[Service]
Type=forking
TimeoutStartSec=120
ExecStart=/root/bin/suse-fb-config.sh
RemainAfterExit=yes
KillMode=process
[Install]
WantedBy=multi-user.target
_EOFCONFIG_
chmod 0644 /etc/systemd/system/suse-fb-config.service
systemctl enable suse-fb-config.service


echo "==========> Exiting userdata script and rebooting.."
systemctl reboot

