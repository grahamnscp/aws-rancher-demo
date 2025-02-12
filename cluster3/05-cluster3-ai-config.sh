#!/bin/bash

source ./params.sh
source ./utils/utils.sh

export KUBECONFIG=./local/admin-cluster3.conf

# --------------------------------------------------------------------
LogStarted "Configuring cluster3.."

# ----------------------------
# deploy nvidia gpu-operator
Log "\_Loading gpu-operator into cluster3.."
cat <<EOF | kubectl apply -f -  > /dev/null 2>&1
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: gpu-operator
  namespace: kube-system
spec:
  chart: gpu-operator
  createNamespace: true
  repo: https://helm.ngc.nvidia.com/nvidia
  targetNamespace: gpu-operator
  valuesContent: |-
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
  version: 24.6.0
EOF

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
# install cert manager crds
Log "\_Loading cert-manager CRDs on cluster3.."
kubectl --kubeconfig=./local/admin-cluster3.conf apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.6.2/cert-manager.crds.yaml

# ----------------------------
# Install suse ai components, db etc..
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment-intro/index.html#suse-ai-deploy-suse-ai

Log "\_Creating suse-ai namespace.."
kubectl --kubeconfig=./local/admin-cluster3.conf create namespace suse-ai

# suse application collection auth
Log "\_Authenticating local helm cli to SUSE Application Collection registry.."
helm registry login dp.apps.rancher.io/charts -u $APPCOL_USER -p $APPCOL_TOKEN

Log "\_Creating a docker-registry secret for SUSE Application Collection.."
kubectl --kubeconfig=./local/admin-cluster3.conf create secret docker-registry application-collection --docker-server=dp.apps.rancher.io --docker-username=$APPCOL_USER --docker-password=$APPCOL_TOKEN -n suse-ai

# ----------------------------
# milvus
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment-intro/index.html#milvus-installing
#  https://github.com/milvus-io/milvus-helm/tree/master/charts/milvus

Log "\_Installing milvus database.."

Log " \_Creating milvus helm chart values.."
cat << MVEOF >./local/cluster3-milvus-values.yaml
global:
  imagePullSecrets:
  - application-collection
cluster:
  enabled: false
standalone:
  persistence:
    persistentVolumeClaim:
      storageClass: longhorn
etcd:
  replicaCount: 1
  persistence:
    storageClassName: longhorn
minio:
  mode: distributed
  replicas: 4
  rootUser: "admin"
  rootPassword: "adminminio"
  persistence:
    storageClass: longhorn
    size: 30Gi
  resources:
    requests:
      memory: 1024Mi
kafka:
  enabled: true
  name: kafka
  replicaCount: 3
  broker:
    enabled: true
  cluster:
    listeners:
      client:
        protocol: 'PLAINTEXT'
      controller:
        protocol: 'PLAINTEXT'
  persistence:
    enabled: true
    annotations: {}
    labels: {}
    existingClaim: ""
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 8Gi
    storageClassName: "longhorn"
MVEOF

#Log " \_Installing milvus database.."
#helm upgrade --kubeconfig=./local/admin-cluster3.conf \
#  --install milvus oci://dp.apps.rancher.io/charts/milvus \
#  -n suse-ai \
#  -f ./local/cluster3-milvus-values.yaml \
#  --timeout=10m

# ollama
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment-intro/index.html#ollama-installing

# open webui
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment-intro/index.html#owui-installing


# ----------------------------
# post install:
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment-intro/index.html#suse-ai-deploy-post

# --------------------------------------------------------------------

LogCompleted "Done."

# tidy up
exit 0
