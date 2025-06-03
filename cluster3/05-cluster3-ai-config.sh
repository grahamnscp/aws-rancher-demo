#!/bin/bash

source ./params.sh
source ./utils/utils.sh
source cluster3/load-tf-output-cluster3.sh

export KUBECONFIG=./local/admin-cluster3.conf

# --------------------------------------------------------------------
LogStarted "Configuring cluster3.."

# ----------------------------
# label agent nodes with GPU

Log "\_Labelling RKE2 Agent nodes on cluster3.."

#  kubectl label node GPU_NODE_NAME accelerator=nvidia-gpu
for agent in `kubectl --kubeconfig=./local/admin-cluster3.conf get nodes | egrep -v "NAME|control-plane" | awk '{print $1}'`
do
  echo labelling agent: $agent
  kubectl --kubeconfig=./local/admin-cluster3.conf label node $agent accelerator=nvidia-gpu
done

# ----------------------------
# deploy nvidia gpu-operator
#  https://documentation.suse.com/suse-ai/1.0/html/NVIDIA-Operator-installation/index.html

#TODO!: the gpu-operator currently breaks the container runtime on the gpu agent nodes
#       work on toml config values to find a combination that works

Log "\_Deploying gpu-operator into cluster3.."

Log "\__Place custom /var/lib/rancher/rke2/agent/etc/containerd/config.toml.tmpl file on agent hosts.."
# create custom config.toml file
#cat << TOMLTEOF > ./local/custom-config.toml
#{{ template "base" . }}
#SystemdCgroup=true .
#TOMLTEOF
cat << TOMLTEOF > ./local/custom-config.toml
SystemdCgroup=true .
TOMLTEOF

# copy custom config.toml.tmpl to agent hosts
for ((i=1; i<=$NUM_AGENTS; i++))
do
  echo "..Checking destination directory exists on agent$i (IP: ${AGENT_PUBLIC_IP[$i]}).."
  ssh $SSH_OPTS ${SSH_USERNAME}@${AGENT_PUBLIC_IP[$i]} "sudo mkdir -p /var/lib/rancher/rke2/agent/etc/containerd"
  echo "..Copying custom config.toml.tmpl to agent$i (IP: ${AGENT_PUBLIC_IP[$i]}).."
  scp $SSH_OPTS ./local/custom-config.toml ${SSH_USERNAME}@${AGENT_PUBLIC_IP[$i]}:~/config.toml
  ssh $SSH_OPTS ${SSH_USERNAME}@${AGENT_PUBLIC_IP[$i]} "sudo cp ~/config.toml /etc/containerd/config.toml"
  ssh $SSH_OPTS ${SSH_USERNAME}@${AGENT_PUBLIC_IP[$i]} "sudo cp ~/config.toml /var/lib/rancher/rke2/agent/etc/containerd/config.toml.tmpl"
done

Log "\__Creating gpu-operator values file.."
cat << GOPEOF > ./local/nvidia-gpu-operator-values.yaml
driver:
 enabled: false
nfd:
 enabled: true
toolkit:
  env:
  - name: CONTAINERD_CONFIG
    value: /var/lib/rancher/rke2/agent/etc/containerd/config.toml.tmpl
  - name: CONTAINERD_SOCKET
    value: /run/k3s/containerd/containerd.sock
  - name: CONTAINERD_RUNTIME_CLASS
    value: nvidia
  - name: CONTAINERD_SET_AS_DEFAULT
    value: "true"
GOPEOF

Log "\__Adding nvidia helm repo.."
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
helm repo update

Log "\__Creating gpu-operator namespace.."
kubectl --kubeconfig=./local/admin-cluster3.conf create namespace gpu-operator
#kubectl --kubeconfig=./local/admin-cluster3.conf label --overwrite ns gpu-operator pod-security.kubernetes.io/enforce=privileged

Log "\__Installing nvidia/gpu-operator helm chart.."
helm upgrade --kubeconfig=./local/admin-cluster3.conf \
  --install gpu-operator nvidia/gpu-operator \
  -n gpu-operator \
  --create-namespace \
  --set driver.enabled=false \
  -f ./local/nvidia-gpu-operator-values.yaml


# --------------------------------------------------------------------

LogCompleted "Done."

# tidy up
exit 0
