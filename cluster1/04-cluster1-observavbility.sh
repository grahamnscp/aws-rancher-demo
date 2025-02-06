#!/bin/bash

source ./params.sh
source ./utils/utils.sh

# -------------------------------------------------------------------------------------
# functions:

#
function installngnixingress
{
  Log "function installngnixingress:"

  kubectl --kubeconfig=./local/admin-cluster1.conf create namespace ingress-nginx

  helm --kubeconfig=./local/admin-cluster1.conf install ingress-nginx ingress-nginx \
       --repo https://kubernetes.github.io/ingress-nginx \
       --namespace ingress-nginx --create-namespace 
}

#
function gensuseobservabilityvalues
{
  Log "function gensuseobservabilityvalues:"

  helm repo add suse-observability https://charts.rancher.com/server-charts/prime/suse-observability
  helm repo update

  # generate values using template
  helm template suse-observability/suse-observability-values \
    --output-dir ./local/ \
    --set license="$OBS_LICENSE" \
    --set baseUrl="https://$OBS_HOSTNAME" \
    --set adminPassword="$OBS_ADMIN_PWD" \
    --set sizing.profile="trial" 

    # Add some basic http ingress for testing  as SUSE Obs needs a real certificate
    cat << EOF >./local/suse-observability-values/templates/ingress_values.yaml
---
# SUSE Observability ingress helm chart values
ingress:
  annotations: {
    kubernetes.io/ingress.class: nginx
  }
  enabled: true
  path: /
  hosts:
    - host: $OBS_HOSTNAME
  # ingress.tls -- List of ingress TLS certificates to use.
  tls:
  #  - secretName: chart-example-tls
  #    hosts:
  #      - stackstate.local
---
EOF

  # Create a bootstrap service token (to add stackpack later)
  cat << EOF >./local/suse-observability-values/templates/authentication.yaml
stackstate:
  authentication:
    serviceToken:
      bootstrap:
        token: $OBS_SERVICE_TOKEN
        roles:
          - stackstate-power-user
        ttl: "24h"
---
EOF

}

#
function installsuseobservability
{
  Log "function installsuseobservability:"

  kubectl --kubeconfig=./local/admin-cluster1.conf create namespace suse-observability

  helm --kubeconfig=./local/admin-cluster1.conf upgrade \
    --install obs suse-observability/suse-observability \
    --namespace suse-observability --create-namespace \
    --values ./local/suse-observability-values/templates/baseConfig_values.yaml \
    --values ./local/suse-observability-values/templates/sizing_values.yaml \
    --values ./local/suse-observability-values/templates/ingress_values.yaml \
    --values ./local/suse-observability-values/templates/authentication.yaml
}

# -------------------------------------------------------------------------------------
# Main

LogStarted "Installing SUSE Observability to cluster1.."

# rke2-nginx-ingress already installed by default
#installngnixingress

# ----------------------------------------
Log "\__Generating suse-observability helm template values.."
gensuseobservabilityvalues

# ----------------------------------------
Log "\__Installing suse-observability on cluster1.."
installsuseobservability

# ----------------------------------------
Log "\__waiting for suse-observability on cluster1 to be Ready.."
kubectl --kubeconfig=./local/admin-cluster1.conf wait pods -n suse-observability -l app.kubernetes.io/instance=obs --for condition=Ready --timeout=900s

# sometimes drops through above and needs a little bit more time
Log "\__sleeping for 1 minute.."
sleep 60

# -------------------------------------------------------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
