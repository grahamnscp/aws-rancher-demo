#!/bin/bash

source ./params.sh
source ./utils/utils.sh

# -------------------------------------------------------------------------------------

CLUSTER_NAME=rancher

LogStarted "Configuring SUSE Observability for $CLUSTER_NAME cluster.."

Log "\__Provisioning kubernetes-v2 stackpack for rancher.."
STS_TOKEN=`cat ./local/sts-token.txt`
curl -sk https://$OBS_HOSTNAME/api/stackpack/kubernetes-v2/provision \
     -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: ApiToken $STS_TOKEN" \
     -d "{\"kubernetes_cluster_name\": \"$CLUSTER_NAME\"}"
echo

# pause for stackpack to deploy fully
sleep 120

Log "\__Installing suse-observability agent on $CLUSTER_NAME.."
obs_api_key=`cat ./local/suse-observability-values/templates/baseConfig_values.yaml  | grep --color=never key | head -1 | awk '{print $2}' | sed 's/\"//g'`
echo obs_api_key: $obs_api_key

# install observability-agent - details via obs UI adding cluster with name $CLUSTER_NAME
helm --kubeconfig=./local/admin.conf upgrade --install suse-observability-agent suse-observability/suse-observability-agent \
     --namespace suse-observability --create-namespace \
     --set-string 'stackstate.apiKey'="$obs_api_key" \
     --set-string 'stackstate.cluster.name'="$CLUSTER_NAME" \
     --set-string 'stackstate.url'="https://$OBS_HOSTNAME/receiver/stsAgent" \
     --set 'nodeAgent.skipKubeletTLSVerify'=true \
     --set-string 'global.skipSslValidation'=true

Log "\__Waiting for suse-observability agent on $CLUSTER_NAME to be Ready.."
kubectl --kubeconfig=./local/admin.conf wait pods -n suse-observability -l app.kubernetes.io/instance=suse-observability-agent --for condition=Ready --timeout=300s

# -------------------------------------------------------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
