#!/bin/bash

source ./params.sh
source ./utils/utils.sh
source ./load-tf-output.sh

export KUBECONFIG=./local/admin.conf
RANCHER_SERVER=rancher.$DOMAINNAME

LogStarted "Rancher Manager Config.."

LogStarted "\__Waiting for Rancher Server to be available (typically route53 delay).."
while true 
do 
  curl -kv https://$RANCHER_SERVER 2>&1 | grep -q "dynamiclistener-ca" 
  if [ $? != 0 ]
  then
    echo "Waiting for Rancher Manager Server to be ready.."
    sleep 5
    continue
  fi
  break
done
echo "Rancher Manager Server is Ready";

Log "\__Authenticating to Rancher Manager API.."
# login with username / password
token=$(curl -sk "https://$RANCHER_SERVER/v3-public/localProviders/local?action=login" \
             -X POST \
             -H 'content-type: application/json' \
             -d "{\"username\":\"admin\",\"password\":\"$BOOTSTRAPADMINPWD\"}" | jq -r .token \
       )
echo token: $token

# obtain api token
api_token=$(curl -sk "https://$RANCHER_SERVER/v3/token" \
             -X POST \
             -H 'content-type: application/json' \
             -H "Authorization: Bearer $token" \
             -d '{"type":"token","description":"automation"}' | jq -r .token \
           )
echo api_token: $api_token

if [ "$api_token" == "" ]
then
  LogError "Failed to get API token, exiting.."
  exit 1
fi

# set rancher server url (needed so rancher cluster import cli creates registration urls)
Log "\__Setting Rancher URL.."
curl -sk "https://$RANCHER_SERVER/v3/settings/server-url" \
     -X PUT \
     -H 'content-type: application/json' \
     -H "Authorization: Bearer $api_token" \
     -d "{\"name\":\"server-url\",\"value\":\"https://$RANCHER_SERVER\"}"

# telemery opt-out setting (removed)
#Log "\__Configure Telemetry Opt-out"
#curl -sk "https://$RANCHER_SERVER/v3/settings/telemetry-opt" \
#     -X PUT \
#     -H 'content-type: application/json' \
#     -H 'accept: application/json' \
#     -H "Authorization: Bearer $api_token" \
#     -d '{"value":"out"}'

Log "\__Overriding min password length.."
cat <<EOF | kubectl apply -f -  > /dev/null 2>&1
apiVersion: management.cattle.io/v3
kind: Setting
metadata:
  name: password-min-length
  namespace: cattle-system
value: "8"
EOF

# change admin password
Log "\__Setting Admin Password.."
curl -sk "https://$RANCHER_SERVER/v3/users?action=changepassword" \
    -X POST \
    -H 'content-type: application/json' \
    -H "Authorization: Bearer $api_token" \
    -d "{\"currentPassword\":\"$BOOTSTRAPADMINPWD\",\"newPassword\":\"$RANCHERADMINPWD\"}"

# add rancher extension repositories
Log "\__Adding Rancher Extensions Repositories.."
# Rancher Extensions repo
cat <<EOF | kubectl apply -f -  > /dev/null 2>&1
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: rancher-ui-plugins
spec:
  gitRepo: https://github.com/rancher/ui-plugin-charts
  gitBranch: main
EOF
# Partner Extensions repo
cat <<EOF | kubectl apply -f -  > /dev/null 2>&1
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: partner-extensions
spec:
  gitRepo: https://github.com/rancher/partner-extensions
  gitBranch: main
EOF

# Add application-collection repo
# secret
cat <<EOF | kubectl apply -f -  > /dev/null 2>&1
apiVersion: v1
kind: Secret
metadata:
  name: clusterrepo-auth-suseappcol
  namespace: cattle-system
type: kubernetes.io/basic-auth
stringData:
  username: $APPCOL_USER
  password: $APPCOL_TOKEN
EOF
# clusterrepo
cat <<EOF | kubectl apply -f -  > /dev/null 2>&1
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: application-collection
  annotations:
    field.cattle.io/description: SUSE Application Collection
spec:
  clientSecret:
    name: clusterrepo-auth-suseappcol
    namespace: cattle-system
  insecurePlainHttp: false
  url: oci://dp.apps.rancher.io/charts
EOF

# Add suse-ai-registry repo
# secret
cat <<EOF | kubectl apply -f -  > /dev/null 2>&1
apiVersion: v1
kind: Secret
metadata:
  name: clusterrepo-auth-suseaireg
  namespace: cattle-system
type: kubernetes.io/basic-auth
stringData:
  username: regcode
  password: $SUSE_AI_SUB
EOF
# clusterrepo
cat <<EOF | kubectl apply -f -  > /dev/null 2>&1
apiVersion: catalog.cattle.io/v1
kind: ClusterRepo
metadata:
  name: suse-ai-registry
  annotations:
    field.cattle.io/description: SUSE AI Registry
spec:
  clientSecret:
    name: clusterrepo-auth-suseaireg
    namespace: cattle-system
  insecurePlainHttp: false
  url: oci://registry.suse.com/ai/charts
EOF

# cattle-ui-plugin-system - suse-ai-lifecycle-manager operator
# https://documentation.suse.com/suse-ai/1.0/html/AI-deployment/ai-alternative-deployments.html#ai-lifecycle-manager-clusterrepo-creating

Log "Creating creating UI Extension Catalog and installing suse-ai-lifecycle-manager on rancher$NODENUM.."

# install operator
helm install suse-ai-operator oci://ghcr.io/suse/chart/suse-ai-operator \
  -n suse-ai-operator-system --create-namespace \
  --version 0.1.0

# Install suse-ai-lifecycle-manager extension, created ui extension catalog and repo
cat <<EOF | kubectl -f -  > /dev/null 2>&1
apiVersion: ai-platform.suse.com/v1alpha1
kind: InstallAIExtension
metadata:
  name: suseai
spec:
  helm:
    name: suse-ai-lifecycle-manager
    url: "oci://ghcr.io/suse/chart/suse-ai-lifecycle-manager"
    version: "1.0.0"
  extension:
    name: suse-ai-lifecycle-manager
    version: "1.0.0"
EOF

#
echo "${BWhi}**************************************"
echo "Rancher Manager is running at:"
echo "open https://$RANCHER_SERVER"
echo "**************************************${RCol}"

LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
