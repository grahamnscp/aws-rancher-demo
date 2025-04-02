#!/bin/bash

source ./params.sh
source ./utils/utils.sh

export KUBECONFIG=./local/admin-cluster3.conf

# --------------------------------------------------------------------
LogStarted "Configuring cluster3.."

# ----------------------------
# deploy nvidia gpu-operator
#  https://documentation.suse.com/suse-ai/1.0/html/NVIDIA-Operator-installation/index.html
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
  --set 'global.imagePullSecrets[0].name'=application-collection

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
  enabled: true
standalone:
  messageQueue: kafka
  persistence:
    enabled: true
    mountPath: "/var/lib/milvus"
    persistentVolumeClaim:
      storageClass: longhorn
      size: 20Gi
etcd:
  replicaCount: 3
  persistence:
    storageClassName: longhorn
minio:
  mode: distributed
  replicas: 4
  rootUser: "admin"
  rootPassword: "adminminio"
  persistence:
    storageClass: longhorn
    size: 10Gi
  resources:
    requests:
      memory: 1024Mi
kafka:
  name: kafka
  enabled: true
  persistence:
    accessModes:
      - ReadWriteOnce
    resources:
      requests:
        storage: 8Gi
    storageClassName: longhorn
MVEOF

Log " \_Installing milvus database.."
helm upgrade --kubeconfig=./local/admin-cluster3.conf \
  --install milvus oci://dp.apps.rancher.io/charts/milvus \
  -n suse-ai \
  -f ./local/cluster3-milvus-values.yaml \
  --timeout=5m

Log " \_Waiting for deployment milvus-standalone rollout.."
kubectl --kubeconfig=./local/admin-cluster3.conf \
        wait pods -n suse-ai \
        -l app.kubernetes.io/instance=milvus --for condition=Ready \
        --timeout=300s

# ----------------------------
# ollama
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment-intro/index.html#ollama-installing
#  https://github.com/otwld/ollama-helm/

# ----------------------------
# open webui
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment-intro/index.html#owui-installing
#  https://documentation.suse.com/suse-ai/1.0/html/openwebui-configuring/index.html
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment-intro/index.html#owui-helm-overrides
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment-intro/index.html#owui-tls-sources

Log "\_Installing open webui.."

Log " \_Creating open webui helm chart values (embedded ollama).."
cat << OWUIEOF >./local/cluster3-owui-values.yaml
global:
  imagePullSecrets:
  - application-collection
image:
  registry: dp.apps.rancher.io
  repository: containers/open-webui
  tag: 0.3.32
  pullPolicy: IfNotPresent
ollamaUrls:
- http://open-webui-ollama.suseai.svc.cluster.local:11434
persistence:
  enabled: true
  storageClass: longhorn
ollama:
  enabled: true
  image:
    registry: dp.apps.rancher.io
    repository: containers/ollama
    tag: 0.3.6
    pullPolicy: IfNotPresent
  imagePullSecrets: application-collection
  ingress:
    enabled: false
  defaultModel: "gemma:2b"
  ollama:
    models:
      - "gemma:2b"
      - "llama3.1"
    gpu:
      enabled: true
      type: 'nvidia'
      number: 1
    persistentVolume:
      enabled: true
      storageClass: longhorn
pipelines:
  enabled: false
  persistence:
    storageClass: longhorn
ingress:
  enabled: true
  class: ""
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  host: $AI_HOSTNAME
  tls: true
extraEnvVars:
- name: DEFAULT_MODELS
  value: "gemma:2b"
- name: DEFAULT_USER_ROLE
  value: "user"
- name: WEBUI_NAME
  value: "SUSE AI"
- name: GLOBAL_LOG_LEVEL
  value: INFO
- name: RAG_EMBEDDING_MODEL
  value: "sentence-transformers/all-MiniLM-L6-v2"
- name: VECTOR_DB
  value: "milvus"
- name: MILVUS_URI
  value: http://milvus.suse-ai.svc.cluster.local:19530
OWUIEOF

Log " \_Installing open webui.."
helm upgrade --kubeconfig=./local/admin-cluster3.conf \
  --install open-webui  oci://dp.apps.rancher.io/charts/open-webui \
  -n suse-ai \
  --version 3.3.2 \
  -f ./local/cluster3-owui-values.yaml \
  --timeout=10m


# ----------------------------
# post install:
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment-intro/index.html#suse-ai-deploy-post
#
#  1. Log in to SUSE AI Open WebUI using the default credentials.
#  2. After you have logged in, update the administrator password for SUSE AI.
#  3. From the available language models, configure the one you prefer. 
#     Optionally, install a custom language model.
#  4. Configure user management with role-base access control (RBAC) as described in 
#     https://documentation.suse.com/suse-ai/1.0/html/openwebui-configuring/index.html#openwebui-managing-user-roles
#  5. Integrate single sign-on authentication manager—such as Okta—with Open WebUI as described in 
#     https://documentation.suse.com/suse-ai/1.0/html/openwebui-configuring/index.html#openwebui-authentication-via-okta.
#  6. Configure retrieval-augmented generation (RAG) to let the model process content relevant to the customer.

# --------------------------------------------------------------------

LogCompleted "Done."

# tidy up
exit 0
