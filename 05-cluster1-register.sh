#!/bin/bash

source ./params.sh
source ./utils.sh
source ./load-tf-output.sh

RANCHER_SERVER=rancher.$DOMAINNAME

LogStarted "Registering downstream cluster1 with Rancher as ImportExisting cluster.."

# fetch token via username / password
token=$(curl -sk "https://$RANCHER_SERVER/v3-public/localProviders/local?action=login" \
             -X POST \
             -H 'content-type: application/json' \
             -d "{\"username\":\"admin\",\"password\":\"$RANCHERADMINPWD\"}" | jq -r .token \
       )
echo token: $token

# pull down rancher ca cert as rancher cli option --skip-verify is ignored atm
Log "\__Downloading Rancher ca cert.."
curl --insecure -s  https://rancher.demo.suselabs.net/cacerts > local/rancher_cacert.pem

# list clusters
#kubectl get clusters.provisioning.cattle.io --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'

# obtain local cluster project for rancher cli context
Log "\__Obtaining Rancher local cluster details for rancher cli login context.."
localns=$(kubectl get projects.management.cattle.io -n local -o=jsonpath='{.items[?(@.spec.displayName=="Default")].metadata.name}')
echo cluster: local project is: $localns

# rancher cli login
Log "\__Authenticating rancher cli.."
rancher login https://$RANCHER_SERVER --token $token --skip-verify --cacert ./local/rancher_cacert.pem --context local:$localns

# clusters
Log "\__Query clusters using rancher cli.."
echo rancher clusters:
rancher cluster ls

# define a cluster of provider type Imported
Log "\__Defining downstream cluster1 in Rancher via rancher cli.."
rancher cluster create cluster1 --import

Log "\__Query clusters using rancher cli.."
echo rancher clusters:
rancher cluster ls

Log "\__Registring cluster1 with Rancher.."
Log " \__Obtaining registration command for cluster1.."
# output downstream import command
curlcmd=$(rancher cluster import cluster1 | grep curl)
importcmd=`echo $curlcmd | sed 's/kubectl/kubectl --kubeconfig=.\/local\/admin-cluster1.conf/'`
echo downstream cluster import command:
echo $importcmd

Log " \__Run kubectl registration command on cluster1 cluster.."
# Registring cluster1 with Rancher..
bash -c "$importcmd"


LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
