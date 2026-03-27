#!/bin/bash

#############################################################
### Note: This script uses the rancher cli                ###
###       Available on macos via brew install rancher-cli ###
#############################################################

source ./params.sh
source ./utils/utils.sh
source ./load-tf-output.sh

RANCHER_SERVER=rancher.$DOMAINNAME

LogStarted "Registering downstream cluster3 with Rancher as ImportExisting cluster.."

# fetch token via username / password
token=$(curl -sk "https://$RANCHER_SERVER/v3-public/localProviders/local?action=login" \
             -X POST \
             -H 'content-type: application/json' \
             -d "{\"username\":\"admin\",\"password\":\"$RANCHERADMINPWD\"}" | jq -r .token \
       )
echo token: $token

# pull down rancher ca cert as rancher cli option --skip-verify is ignored atm
Log "\__Downloading Rancher ca cert.."
curl --insecure -s  https://$RANCHER_SERVER/cacerts > ./local/rancher_cacert.pem

# list clusters
#kubectl --kubeconfig=./local/admin.conf get clusters.provisioning.cattle.io --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'

# obtain local cluster project for rancher cli context
Log "\__Obtaining Rancher local cluster details for rancher cli login context.."
localns=$(kubectl --kubeconfig=./local/admin.conf get projects.management.cattle.io -n local -o=jsonpath='{.items[?(@.spec.displayName=="Default")].metadata.name}')
echo cluster: local project is: $localns

# rancher cli login
KUBECONFIG=/Users/grahamh/lab/aws-rancher-demo/local/admin.conf
Log "\__Authenticating rancher cli.."
rancher login https://$RANCHER_SERVER --token $token --skip-verify --cacert ./local/rancher_cacert.pem --context local:$localns

# clusters
Log "\__Query clusters using rancher cli.."
echo rancher clusters:
rancher cluster ls

# define a cluster of provider type Imported
Log "\__Defining downstream cluster3 (as ai) in Rancher via rancher cli.."
rancher cluster create ai --import

sleep 5

Log "\__Query clusters using rancher cli.."
echo rancher clusters:
rancher cluster ls

Log "\__Registring cluster3 with Rancher.."
Log " \__Obtaining registration command for cluster3.."
# output downstream import command
curlcmd=$(rancher cluster import ai | grep --color=never curl)
importcmd=`echo $curlcmd | sed 's/kubectl/kubectl --kubeconfig=.\/local\/admin-cluster3.conf/'`
echo downstream cluster import command:
echo $importcmd

Log " \__Run kubectl registration command on cluster3 cluster.."
# Registring cluster3 with Rancher..
bash -c "$importcmd"


# Add ClusterRepos to AI cluster

# Add application-collection repo
Log "\__Adding application-collection ClusterRepo to AI cluster.."
# secret
cat <<EOF | kubectl --kubeconfig=./local/admin-cluster3.conf apply -f -  > /dev/null 2>&1
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
cat <<EOF | kubectl --kubeconfig=./local/admin-cluster3.conf apply -f -  > /dev/null 2>&1
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
Log "\__Adding suse-ai-registry ClusterRepo to AI cluster.."
# secret
cat <<EOF | kubectl --kubeconfig=./local/admin-cluster3.conf apply -f -  > /dev/null 2>&1
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
cat <<EOF | kubectl --kubeconfig=./local/admin-cluster3.conf apply -f -  > /dev/null 2>&1
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


LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
