#!/bin/bash

source ./params.sh
source ./utils/utils.sh
source cluster3/load-tf-output-cluster3.sh

# -------------------------------------------------------------------------------------
# functions:

#
function longhornstoragescript
{
  Log "function longhornstoragescript:"

  cat << EOF >./local/cluster3-longhorn-partition.sh
#!/bin/bash

VGNAME="vg_longhorn"
LVNAME="storage"
MOUNTPOINT="/var/lib/longhorn"

STORAGE_DEV=$STORAGE_DEV1

# Create a single partition for the whole disk
sfdisk /dev/\${STORAGE_DEV} <<- EOF1
label: gpt
type=linux
EOF1

# pause for a beat
sleep 2
partprobe

PARTITION="/dev/\${STORAGE_DEV}p1"

# Remove all the previous content (probably not needed)
wipefs --all \${PARTITION}

# Create a PV on top of the partition
lvm pvcreate \${PARTITION}

# Add it to the list of PVs so vgcreate can be easily executed
PVS+=" \${PARTITION}"

# Create a VG with all the PVs
lvm vgcreate \${VGNAME} \${PVS}

# A LV with all the free space, -Z is needed because there is no udev it seems
lvm lvcreate -Zn -l 100%FREE -n \${LVNAME} \${VGNAME}
mkfs.xfs /dev/mapper/\${VGNAME}-\${LVNAME}
mkdir -p \${MOUNTPOINT}
echo "/dev/mapper/\${VGNAME}-\${LVNAME} \${MOUNTPOINT} xfs noatime 0 0" >> /etc/fstab
mount \${MOUNTPOINT}

EOF
}

#
function mountlonghornstorage
{
  NODENUM=$1

  Log "function mountlonghornstorage: for master node $NODENUM"

  ANODEIP=${NODE_PUBLIC_IP[$NODENUM]}
  ANODENAME=${NODE_NAME[$NODENUM]}
  APRIVATEIP=${NODE_PRIVATE_IP[$NODENUM]}
  ANODEN=$(echo $ANODENAME | cut -d. -f1)

  Log "\__Partitioning storage disk on node $ANODENAME"

  scp $SSH_OPTS ./local/cluster3-longhorn-partition.sh ${SSH_USERNAME}@${ANODEIP}:~/
  ssh $SSH_OPTS ${SSH_USERNAME}@${ANODEIP} "sudo chmod +x ~/cluster3-longhorn-partition.sh"
  ssh $SSH_OPTS ${SSH_USERNAME}@${ANODEIP} "sudo ~/cluster3-longhorn-partition.sh 2>&1 > ~/cluster3-longhorn-partition.log 2>&1"
}

#
function mountlonghornstorage-agent
{
  NODENUM=$1

  Log "function mountlonghornstorage-agent: for agent node $NODENUM"

  ANODEIP=${AGENT_PUBLIC_IP[$NODENUM]}
  ANODENAME=${AGENT_NAME[$NODENUM]}
  APRIVATEIP=${AGENT_PRIVATE_IP[$NODENUM]}
  ANODEN=$(echo $ANODENAME | cut -d. -f1)

  Log "\__Partitioning storage disk on node $ANODENAME"

  scp $SSH_OPTS ./local/cluster3-longhorn-partition.sh ${SSH_USERNAME}@${ANODEIP}:~/
  ssh $SSH_OPTS ${SSH_USERNAME}@${ANODEIP} "sudo chmod +x ~/cluster3-longhorn-partition.sh"
  ssh $SSH_OPTS ${SSH_USERNAME}@${ANODEIP} "sudo ~/cluster3-longhorn-partition.sh 2>&1 > ~/cluster3-longhorn-partition.log 2>&1"
}

#
function helminstalllonghorn
{
  Log "function helminstalllonghorn:"

  # create namespace
  kubectl --kubeconfig=./local/admin-cluster3.conf create namespace longhorn-system

  # helm install longhorn
  helm repo add longhorn https://charts.longhorn.io
  helm repo update

  Log " \_Creating longhorn helm chart values.."
  cat << LEOF >./local/longhorn-values.yaml
persistence:
  defaultClass: true
  defaultFsType: xfs
LEOF

  Log " \_Installing longhorn helm chart.."
  helm upgrade --kubeconfig=./local/admin-cluster3.conf \
  --install longhorn longhorn/longhorn \
  --namespace longhorn-system \
  -f ./local/longhorn-values.yaml \
  --timeout=5m
}


# -------------------------------------------------------------------------------------
# Main
LogStarted "Installing Longhorn on cluster3.."

Log "\__Generating longhorn storage script.."
# generate partitioning script
longhornstoragescript $node

Log "\__Mounting longhorn volume on cluster3 master nodes.."
# mounts longhorn storage on each master node
for node in $(seq 1 3);
do
  mountlonghornstorage $node
  LogElapsedDuration
done

Log "\__Mounting longhorn volume on cluster3 agent nodes.."
# mounts longhorn storage on each agent node
for ((node=1; node<=$NUM_AGENTS; node++))
do
  mountlonghornstorage-agent $node
  LogElapsedDuration
done

Log "\__Installing longhorn on cluster3 via helm.."
helminstalllonghorn


# -------------------------------------------------------------------------------------

# tidy up
exit 0
