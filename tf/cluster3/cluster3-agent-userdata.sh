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


# Nvidia Drivers:
#
#  Install open prebuilt/secureboot-signed Kernel driver
zypper --non-interactive install --auto-agree-with-licenses nvidia-open-driver-G06-signed-cuda-kmp-default
#
#  Ensure userspace CUDA drivers in sync with open prebuilt/secureboot-signed Kernel driver
version=$(rpm -qa --queryformat '%{VERSION}\n' nvidia-open-driver-G06-signed-cuda-kmp-default | cut -d "_" -f1 | sort -u | tail -n 1)
#
#   Install CUDA drivers
zypper addrepo --refresh https://download.nvidia.com/suse/sle15sp7/ nvidia-cuda
zypper --gpg-auto-import-keys refresh
zypper --non-interactive install --auto-agree-with-licenses nvidia-compute-utils-G06 == ${version} nvidia-persistenced == ${version}

updatedb


# Create a systemd config script for first boot only
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

# Tuning
# Environment: promtail on amd64 EC2
echo "fs.inotify.max_user_instances = 1024" | tee -a /etc/sysctl.conf
sysctl -p
sysctl fs.inotify

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

