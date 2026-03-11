#!/bin/bash

source ./params.sh
source ./utils/utils.sh
source cluster3/load-tf-output-cluster3.sh

export KUBECONFIG=./local/admin-cluster3.conf

# --------------------------------------------------------------------
LogStarted "Configuring cluster3 ready for SUSE AI deployment.."

# label agent nodes with GPU
Log "\_Labelling RKE2 Agent nodes on cluster3.."

#  kubectl label node GPU_NODE_NAME accelerator=nvidia-gpu
for agent in `kubectl --kubeconfig=./local/admin-cluster3.conf get nodes | egrep -v "NAME|control-plane" | awk '{print $1}'`
do
  echo labelling agent: $agent
  kubectl --kubeconfig=./local/admin-cluster3.conf label node $agent accelerator=nvidia-gpu
  kubectl --kubeconfig=./local/admin-cluster3.conf label node $agent hardware-type=nvidia-gpu
done

# Add nvidia toolkit to kubernetes path
Log "\_Adding /usr/local/nvidia/toolkit to PATH env on Agent nodes.."
# Add nvidia toolkit to path
for ((i=1; i<=$NUM_AGENTS; i++))
do
  AAGENTNAME=${AGENT_NAME[$i]}
  AAGENTIP=${AGENT_PUBLIC_IP[$i]}
  AAGENTN=$(echo $i | cut -d. -f1)
  ssh $SSH_OPTS ${SSH_USERNAME}@${AAGENTIP} 'sudo echo PATH=$PATH:/usr/local/nvidia/toolkit >> ~/./rke2-agent'
done

# test gpu env pod (will not schedule until nvidia operator deploys)
Log "\__Deploy CUDA test pod.."
Log "\__Creating gpu-operator values file.."
cat << TESTEOF > ./local/test-gpu-runtime.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nbody-gpu-benchmark
  namespace: default
spec:
  restartPolicy: OnFailure
  runtimeClassName: nvidia
  containers:
  - name: cuda-container
    image: nvcr.io/nvidia/k8s/cuda-sample:nbody
    args: ["nbody", "-gpu", "-benchmark"]
    resources:
      limits:
        nvidia.com/gpu: 1
    env:
    - name: NVIDIA_VISIBLE_DEVICES
      value: all
    - name: NVIDIA_DRIVER_CAPABILITIES
      value: all
TESTEOF
kubectl --kubeconfig=./local/admin-cluster3.conf apply -f ./local/test-gpu-runtime.yaml

# --------------------------------------------------------------------
# deploy nvidia gpu-operator
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment/suse-ai-deploy-prepare.html#nvidia-operator-installation
#  https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/troubleshooting.html
# ----------------------------

Log "\_Deploying gpu-operator into cluster3.."

Log "\__Creating gpu-operator values file.."
cat << GOPEOF > ./local/nvidia-gpu-operator-values.yaml
driver:
 enabled: false
nfd:
 enabled: true
toolkit:
  env:
  - name: CONTAINERD_SOCKET
    value: /run/k3s/containerd/containerd.sock
  - name: CONTAINERD_RUNTIME_CLASS
    value: nvidia
  - name: CONTAINERD_SET_AS_DEFAULT
    value: "false"
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
  -f ./local/nvidia-gpu-operator-values.yaml \
  --set driver.enabled=false
#  --set cdi.enabled=true --set cdi.default=true

# --------------------------------------------------------------------

Log "Preparing for downstream cluster suse ai component deployment.."

Log "\_Creating suse-ai namespace.."
kubectl --kubeconfig=./local/admin-cluster3.conf create namespace suse-ai

# suse application collection auth
Log "\_Authenticating local helm cli to SUSE Application Collection registry.."
helm registry login dp.apps.rancher.io -u $APPCOL_USER -p $APPCOL_TOKEN

Log "\_Creating a docker-registry secret for SUSE Application Collection.."
kubectl --kubeconfig=./local/admin-cluster3.conf create secret docker-registry application-collection --docker-server=dp.apps.rancher.io --docker-username=$APPCOL_USER --docker-password=$APPCOL_TOKEN -n suse-ai

# ----------------------------
# install cert manager

Log "\_Creating cert-manager namespace.."
kubectl --kubeconfig=./local/admin-cluster3.conf create namespace cert-manager

Log "\_Creating application-collection secret for cert-manager.."
kubectl --kubeconfig=./local/admin-cluster3.conf create secret docker-registry application-collection --docker-server=dp.apps.rancher.io --docker-username=$APPCOL_USER --docker-password=$APPCOL_TOKEN -n cert-manager

Log "\_Installing cert-manager on cluster3.."
helm upgrade --kubeconfig=./local/admin-cluster3.conf --install cert-manager \
  oci://dp.apps.rancher.io/charts/cert-manager \
  -n cert-manager \
  --timeout=5m \
  --set crds.enabled=true \
  --set global.imagePullSecrets={application-collection}
#  --set 'global.imagePullSecrets[0].name'=application-collection


# --------------------------------------------------------------------

LogCompleted "Done."

# tidy up
exit 0
