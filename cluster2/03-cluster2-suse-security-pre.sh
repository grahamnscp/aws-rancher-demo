#!/bin/bash

source ./params.sh
source ./utils/utils.sh

# -------------------------------------------------------------------------------------
# functions:

#
function installngnixingress
{
  Log "function installngnixingress:"

  kubectl --kubeconfig=./local/admin-cluster2.conf create namespace ingress-nginx

  helm --kubeconfig=./local/admin-cluster2.conf install ingress-nginx ingress-nginx \
       --repo https://kubernetes.github.io/ingress-nginx \
       --namespace ingress-nginx --create-namespace 
}

#
function installcertmanager
{
  kubectl apply --kubeconfig=./local/admin-cluster2.conf -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml

  helm repo add jetstack https://charts.jetstack.io
  helm repo update

  helm upgrade --install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.13.3 --kubeconfig=./local/admin-cluster2.conf
  kubectl wait pods -n cert-manager --kubeconfig=./local/admin-cluster2.conf -l app.kubernetes.io/instance=cert-manager --for condition=Ready
}

#
function createselfsignedissuer
{
  # To automatically generate selfsigned TLS certificate - configure a ClusterIssuer in cert-manager to reference
  # cluster cert issuer
  cat <<EOF | kubectl apply --kubeconfig=./local/admin-cluster2.conf -f -
  apiVersion: cert-manager.io/v1
  kind: ClusterIssuer
  metadata:
    name: selfsigned-cluster-issuer
  spec:
    selfSigned: {}
EOF
  kubectl --kubeconfig=./local/admin-cluster2.conf get ClusterIssuers -n cert-manager
}

# -------------------------------------------------------------------------------------
# Main

LogStarted "Installing SUSE Security to cluster2.."

# install full nginx ingress to cluster (already present on rke2 cluster)
#installngnixingress

LogStarted "\__Installing cert-manager on cluster2.."
installcertmanager
createselfsignedissuer

LogStarted "\__Creating cattle-neuvector-system namespace on cluster2.."
kubectl --kubeconfig=./local/admin-cluster2.conf create namespace cattle-neuvector-system
kubectl --kubeconfig=./local/admin-cluster2.conf label namespace cattle-neuvector-system "pod-security.kubernetes.io/enforce=privileged"

# -------------------------------------------------------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
