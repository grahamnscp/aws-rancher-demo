#!/bin/bash

source ./params.sh
source ./utils/utils.sh

# -------------------------------------------------------------------------------------

LogStarted "Configuring SUSE Observability on cluster1.."

# ----------------------------------------
Log "\__Configure sts cli.."
TOKEN_READY=false
while ! $TOKEN_READY
do
  ./utils/so-token-fetcher --url https://$OBS_HOSTNAME --username admin --password $OBS_ADMIN_PWD -auth-type default -o ./local/sts-token.txt
  STS_TOKEN=`cat ./local/sts-token.txt`
  if [ "$STS_TOKEN" == "" ]; then
    sleep 30
  else
    TOKEN_READY=true
  fi
done
echo sts-token: $STS_TOKEN

mkdir -p ~/.config/stackstate-cli
cat << EOF >~/.config/stackstate-cli/config.yaml
contexts:
    - name: default
      context:
        url: https://$OBS_HOSTNAME
        api-token: $STS_TOKEN
        api-path: /api
        admin-api-path: ""
        skip-ssl: true
current-context: default
EOF

# ----------------------------------------

Log "\__Provisioning kubernetes-v2 stackpack.."
CLUSTER_NAME=cluster1
curl -sk https://$OBS_HOSTNAME/api/stackpack/kubernetes-v2/provision \
     -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: ApiToken $STS_TOKEN" \
     -d "{\"kubernetes_cluster_name\": \"$CLUSTER_NAME\"}"
echo

Log "\__Provisioning open-telemetry stackpack.."
curl -sk https://$OBS_HOSTNAME/api/stackpack/open-telemetry/provision \
     -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: ApiToken $STS_TOKEN" \
     -d '{}' 
echo 

Log "\__Provisioning Autonomous Anomaly Detector stackpack.."
curl -sk https://$OBS_HOSTNAME/api/stackpack/aad-v2/provision \
     -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: ApiToken $STS_TOKEN" \
     -d '{}'
echo

# ----------------------------------------
# Add local receiver agent on observability cluster

# pause for stackpacks to deploy fully
sleep 120

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

Log "\__Installing suse-observability agent on cluster1.."
obs_api_key=`cat ./local/suse-observability-values/templates/baseConfig_values.yaml  | grep --color=never key | head -1 | awk '{print $2}' | sed 's/\"//g'`
echo obs_api_key: $obs_api_key

# install observability-agent - details via obs UI adding cluster with name 'cluster1'
helm --kubeconfig=./local/admin-cluster1.conf upgrade --install suse-observability-agent suse-observability/suse-observability-agent \
     --namespace suse-observability --create-namespace \
     --set-string 'stackstate.apiKey'="$obs_api_key" \
     --set-string 'stackstate.cluster.name'='cluster1' \
     --set-string 'stackstate.url'="https://$OBS_HOSTNAME/receiver/stsAgent" \
     --set 'nodeAgent.skipKubeletTLSVerify'=true \
     --set-string 'global.skipSslValidation'=true

Log "\__Waiting for suse-observability agent on cluster1 to be Ready.."
kubectl --kubeconfig=./local/admin-cluster1.conf wait pods -n suse-observability -l app.kubernetes.io/instance=suse-observability-agent --for condition=Ready --timeout=300s

# -------------------------------------------------------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
