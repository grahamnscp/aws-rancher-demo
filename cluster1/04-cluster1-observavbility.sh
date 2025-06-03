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

    # Add some basic http ingress for testing as SUSE Obs needs a real certificate
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
opentelemetry:
  enabled: true
opentelemetry-collector:
  ingress:
    enabled: true
    ingressClassName: nginx
    annotations:
      nginx.ingress.kubernetes.io/proxy-body-size: "50m"
      nginx.ingress.kubernetes.io/backend-protocol: GRPC
      cert-manager.io/cluster-issuer: selfsigned-issuer
    hosts:
      - host: otlp-$OBS_HOSTNAME
        paths:
          - path: /
            pathType: Prefix
            port: 4317
    tls:
      - hosts:
          - otlp-$OBS_HOSTNAME
        secretName: otlp-tls-secret
    additionalIngresses:
      - name: otlp-http
        annotations:
          nginx.ingress.kubernetes.io/proxy-body-size: "50m"
          cert-manager.io/cluster-issuer: selfsigned-issuer
        hosts:
          - host: otlp-http-$OBS_HOSTNAME
            paths:
              - path: /
                pathType: Prefix
                port: 4318
        tls:
          - hosts:
              - otlp-http-$OBS_HOSTNAME
            secretName: otlp-http-tls-secret 
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
function installcertmanager
{
  Log "function installcertmanager:"

  kubectl --kubeconfig=./local/admin-cluster1.conf create namespace cert-manager

  kubectl --kubeconfig=./local/admin-cluster1.conf create secret docker-registry application-collection --docker-server=dp.apps.rancher.io --docker-username=$APPCOL_USER --docker-password=$APPCOL_TOKEN -n cert-manager

  helm upgrade --kubeconfig=./local/admin-cluster1.conf --install cert-manager \
    oci://dp.apps.rancher.io/charts/cert-manager \
    -n cert-manager \
    --timeout=5m \
    --set crds.enabled=true \
    --set 'global.imagePullSecrets[0].name'=application-collection

  kubectl wait pods -n cert-manager -l app.kubernetes.io/instance=cert-manager --for condition=Ready

  # issuer
  cat << EOF >./local/cluster1-selfsigned-issuer.yaml 
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
EOF

  kubectl --kubeconfig=./local/admin-cluster1.conf apply -f ./local/cluster1-selfsigned-issuer.yaml
  kubectl --kubeconfig=./local/admin-cluster1.conf wait --for=condition=Ready clusterissuer --all --timeout=300s
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
Log "\__Installing cert-manager on cluster.."
installcertmanager

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
# Obtain Obs API-KEY from baseConfig_valuses

OBS_API_KEY=`cat ./local/suse-observability-values/templates/baseConfig_values.yaml  | grep --color=never key | head -1 | awk '{print $2}' | sed 's/\"//g'`
echo $OBS_API_KEY > ./local/obs-apikey.txt
echo OBS_API_KEY: $OBS_API_KEY

# -------------------------------------------------------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
