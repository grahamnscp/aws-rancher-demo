#!/bin/bash

source ./params.sh
source ./utils/utils.sh
source ./load-tf-output.sh

export KUBECONFIG=./local/admin.conf

LogStarted "Installing Rancher Manager.."


Log "\__Add helm repo jetstack (for cert-manager).."
helm repo add jetstack https://charts.jetstack.io
helm repo update

Log "\__helm install cert-manager jetstack/cert-manager .."
helm install --kubeconfig=./local/admin.conf cert-manager jetstack/cert-manager \
        --namespace cert-manager --create-namespace \
        --set crds.enabled=true

#        --set installCRDs=true
#⚠️  WARNING: `installCRDs` is deprecated, use `crds.enabled` instead.

LogElapsedDuration

Log "\__Add helm repo rancher-latest.."
helm repo add rancher-prime https://charts.rancher.com/server-charts/prime
#helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
#helm search repo rancher-prime --versions
#helm show values rancher-prime/rancher
helm repo update

Log "\__helm install rancher (version=${RANCHERVERSION}).."
#helm install rancher rancher-latest/rancher --namespace cattle-system --create-namespace \
helm install --kubeconfig=./local/admin.conf rancher rancher-prime/rancher \
        --namespace cattle-system --create-namespace \
        --version=${RANCHERVERSION} \
        --set hostname=rancher.$DOMAINNAME \
        --set bootstrapPassword=${BOOTSTRAPADMINPWD} \
        --set noDefaultAdmin=false \
        --set agentTLSMode=system-store

# wait until cluster fully up
Log "\__Waiting for Rancher Manager to be fully initialised.."

kubectl --kubeconfig=./local/admin.conf -n cattle-system rollout status deploy/rancher

sleep 30
READY=false
while ! $READY
do
  NRC=`kubectl --kubeconfig=./local/admin.conf get pods --all-namespaces 2>&1 | egrep -v 'Running|Completed|NAMESPACE' | wc -l`
  if [ $NRC -eq 0 ]; then
    echo -n 0
    echo
    Log " \__Rancher is now initialised."
    READY=true
  else
    echo -n ${NRC}.
    sleep 10
  fi
done

LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
