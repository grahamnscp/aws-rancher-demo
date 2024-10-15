#!/bin/bash

source ./params.sh
source ./utils.sh
source ./load-tf-output.sh

export KUBECONFIG=./local/admin.conf
RANCHER_SERVER=rancher.$DOMAINNAME

LogStarted "Rancher Manager Config.."


# obtain api token using bootsrap password
token=$(curl -sk -X POST https://$RANCHER_SERVER/v3-public/localProviders/local?action=login -H 'content-type: application/json' -d '{"username":"admin","password":"$BOOTSTRAPADMINPWD"}' | jq -r .token)
api_token=$(curl -sk -X POST https://$RANCHER_SERVER/v3/token -H 'content-type: application/json' -H "Authorization: Bearer $token" -d '{"type":"token","description":"automation"}' | jq -r .token)

# set rancher server url
#curl -sk https://$RANCHER_SERVER/v3/settings/server-url -H 'content-type: application/json' -H "Authorization: Bearer $api_token" -X PUT -d '{"name":"server-url","value":"https://$RANCHER_SERVER"}'  > /dev/null 2>&1

Log "\__Configure Telemetry Opt-out"
curl -sk https://$RANCHER_SERVER/v3/settings/telemetry-opt -X PUT -H 'content-type: application/json' -H 'accept: application/json' -H "Authorization: Bearer $api_token" -d '{"value":"out"}' > /dev/null 2>&1

Log "\__Overriding min password length"
cat <<EOF | kubectl apply -f -  > /dev/null 2>&1
apiVersion: management.cattle.io/v3
kind: Setting
metadata:
  name: password-min-length
  namespace: cattle-system
value: "8"
EOF

LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
