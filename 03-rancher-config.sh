#!/bin/bash

source ./params.sh
source ./utils.sh
source ./load-tf-output.sh

export KUBECONFIG=./local/admin.conf
RANCHER_SERVER=rancher.$DOMAINNAME

LogStarted "Rancher Manager Config.."
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

# telemery opt-out setting
Log "\__Configure Telemetry Opt-out"
curl -sk "https://$RANCHER_SERVER/v3/settings/telemetry-opt" \
     -X PUT \
     -H 'content-type: application/json' \
     -H 'accept: application/json' \
     -H "Authorization: Bearer $api_token" \
     -d '{"value":"out"}'

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

#
echo "${BWhi}**************************************"
echo "Rancher Manager is running at:"
echo "open https://$RANCHER_SERVER"
echo "**************************************${RCol}"

LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
