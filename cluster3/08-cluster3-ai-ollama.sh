#!/bin/bash

source ./params.sh
source ./utils/utils.sh

export KUBECONFIG=./local/admin-cluster3.conf

# --------------------------------------------------------------------
LogStarted "Installing suse-ai ollama on cluster3.."

# --------------------------------------------------------------------
# ollama
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment/ai-library-installing.html#ollama-installing
#  https://github.com/otwld/ollama-helm/
# --------------------------------------------------------------------

Log " \_Creating ollama helm chart values.."
cat << EOF >./local/cluster3-ollama-values.yaml
global:
  imagePullSecrets:
  - application-collection
ingress:
  enabled: false
defaultModel: "gemma:2b"
ollama:
  gpu:
    enabled: true
    type: 'nvidia'
    number: 1
    nvidiaResource: "nvidia.com/gpu"
  models:
    pull:
      - "gemma:2b"
    run:
      - "gemma:2b"
persistentVolume:
  enabled: true
  storageClass: longhorn
  size: 50Gi
extraEnv:
  - name: OLLAMA_DEBUG
    value: "1"
runtimeClassName: "nvidia"
EOF

# deploy ollama

# chart versions: curl -s -u "$APPCOL_USER:$APPCOL_TOKEN" https://dp.apps.rancher.io/v2/charts/ollama/tags/list | jq

Log " \_Installing ollama.."
helm upgrade --kubeconfig=./local/admin-cluster3.conf \
  --install ollama oci://dp.apps.rancher.io/charts/ollama \
  -n suse-ai \
  -f ./local/cluster3-ollama-values.yaml \
  --timeout=5m

Log " \_Waiting for deployment ollama rollout.."
kubectl --kubeconfig=./local/admin-cluster3.conf \
  wait pods -n suse-ai \
  -l app.kubernetes.io/instance=ollama --for condition=Ready \
  --timeout=300s

# --------------------------------------------------------------------

LogCompleted "Done."

# tidy up
exit 0
