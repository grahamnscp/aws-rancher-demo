#!/bin/bash

source ./params.sh
source ./utils.sh
source ./load-tf-output.sh

export KUBECONFIG=./local/admin.conf
RANCHER_SERVER=rancher.$DOMAINNAME

LogStarted "Rancher Manager Config.."
BOOTSTRAPADMINPWD=rancher123
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

# set rancher server url
#curl -sk "https://$RANCHER_SERVER/v3/settings/server-url" -H 'content-type: application/json' -H "Authorization: Bearer $api_token" -X PUT -d '{"name":"server-url","value":"https://$RANCHER_SERVER"}'  > /dev/null 2>&1

Log "\__Configure Telemetry Opt-out"
curl -sk "https://$RANCHER_SERVER/v3/settings/telemetry-opt" \
     -X PUT \
     -H 'content-type: application/json' \
     -H 'accept: application/json' \
     -H "Authorization: Bearer $api_token" \
     -d '{"value":"out"}' \
     > /dev/null 2>&1

Log "\__Overriding min password length"
cat <<EOF | kubectl apply -f -  > /dev/null 2>&1
apiVersion: management.cattle.io/v3
kind: Setting
metadata:
  name: password-min-length
  namespace: cattle-system
value: "8"
EOF

# change admin password
#Log "\__Setingt Admin Password"
#curl -sk "https://$RANCHER_SERVER/v3/users?action=changepassword" \
#    -X POST \
#    -H 'content-type: application/json' \
#    -H "Authorization: Bearer $api_token" \
#    -d '{"currentPassword":"$BOOTSTRAPADMINPWD","newPassword":"$RANCHERADMINPWD"}' \
#    > /dev/null 2>&1


#
echo "Rancher Manager is running at https://$RANCHER_SERVER"

LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
