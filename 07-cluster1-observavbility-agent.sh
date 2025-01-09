#!/bin/bash

source ./params.sh
source ./utils.sh

# -------------------------------------------------------------------------------------
# Check obs server pod is running first
  Log "\_Waiting for SUSE Observability server to be up.."
  READY=false
  while ! $READY
  do
    OBS_SERVER_UP=`kubectl get deployment/obs-suse-observability-server -n suse-observability --kubeconfig=./local/admin-cluster1.conf | grep 1/1 | wc -l`
    if [ $OBS_SERVER_UP -eq 1 ]; then
      echo -n 1
      echo
      READY=true
    else
      echo -n .
      sleep 10
    fi
  done

# -------------------------------------------------------------------------------------
Log "\__Installing suse-observability agent on cluster1.."
# fetch generated apikey from values template
#obs_api_key=`cat ./local/suse-observability-values/templates/baseConfig_values.yaml | grep --color=never receiverApiKey | awk '{print $2}' | sed 's/\"//g'`
obs_api_key=`cat ./local/suse-observability-values/templates/baseConfig_values.yaml  | grep key | head -1 | awk '{print $2}' | sed 's/\"//g'`
echo obs_api_key: $obs_api_key

# install observability-agent - details via obs UI adding cluster with name 'cluster1'
helm --kubeconfig=./local/admin-cluster1.conf upgrade --install suse-observability-agent suse-observability/suse-observability-agent \
     --namespace suse-observability --create-namespace \
     --set-string 'stackstate.apiKey'="$obs_api_key" \
     --set-string 'stackstate.cluster.name'='cluster1' \
     --set-string 'stackstate.url'="https://$OBS_HOSTNAME/receiver/stsAgent" \
     --set 'nodeAgent.skipKubeletTLSVerify'=true \
     --set-string 'global.skipSslValidation'=true 

# -------------------------------------------------------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
