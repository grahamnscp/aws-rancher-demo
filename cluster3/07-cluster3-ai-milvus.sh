#!/bin/bash

source ./params.sh
source ./utils/utils.sh

export KUBECONFIG=./local/admin-cluster3.conf

# --------------------------------------------------------------------
LogStarted "Installing suse-ai on cluster3.."

# --------------------------------------------------------------------
# milvus
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment/ai-library-installing.html#milvus-installing
#  https://github.com/milvus-io/milvus-helm/tree/master/charts/milvus
# --------------------------------------------------------------------

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
  cluster:
    nodeCount:
      broker: 1
      controller: 1
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

# --------------------------------------------------------------------

LogCompleted "Done."

# tidy up
exit 0
