#!/bin/bash

source ./params.sh
source ./utils/utils.sh

# -------------------------------------------------------------------------------------

AI_CLUSTER_NAME=cluster3
STS_TOKEN=`cat ./local/sts-token.txt`

LogStarted "Configuring $AI_CLUSTER_NAME for SUSE Observability.."

# -------------------------------------------------------------------------------------
Log "\_Provisioning kubernetes-v2 stackpack for $AI_CLUSTER_NAME on Observability cluster.."

curl -sk https://$OBS_HOSTNAME/api/stackpack/kubernetes-v2/provision \
     -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: ApiToken $STS_TOKEN" \
     -d "{\"kubernetes_cluster_name\": \"$AI_CLUSTER_NAME\"}"
echo

# -------------------------------------------------------------------------------------
# Add local receiver agent on cluster3

# pause for stackpacks to deploy fully
sleep 120

Log "\_Installing suse-observability agent on $AI_CLUSTER_NAME.."

OBS_API_KEY=`cat ./local/obs-apikey.txt`

# install observability-agent - details via obs UI adding cluster with name $AI_CLUSTER_NAME
helm --kubeconfig=./local/admin-cluster3.conf upgrade --install suse-observability-agent suse-observability/suse-observability-agent \
     --namespace suse-observability --create-namespace \
     --set-string 'stackstate.apiKey'="$OBS_API_KEY" \
     --set-string 'stackstate.cluster.name'="$AI_CLUSTER_NAME" \
     --set-string 'stackstate.url'="https://$OBS_HOSTNAME/receiver/stsAgent" \
     --set 'nodeAgent.skipKubeletTLSVerify'=true \
     --set-string 'global.skipSslValidation'=true

Log "\__Waiting for suse-observability agent on $AI_CLUSTER_NAME to be Ready.."
kubectl --kubeconfig=./local/admin-cluster3.conf wait pods -n suse-observability -l app.kubernetes.io/instance=suse-observability-agent --for condition=Ready --timeout=300s


# -------------------------------------------------------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
