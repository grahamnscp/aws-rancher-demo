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
function installcertmanager
{
  Log "function installcertmanager:"

  Log "\___Creating cert-manager namespace.."
  kubectl --kubeconfig=./local/admin-cluster1.conf create namespace cert-manager

  Log "\___Creating application-collection secret.."
  kubectl --kubeconfig=./local/admin-cluster1.conf create secret docker-registry application-collection --docker-server=dp.apps.rancher.io --docker-username=$APPCOL_USER --docker-password=$APPCOL_TOKEN -n cert-manager

  Log "\___Installing application collection cert-manager helm chart.."
  helm upgrade --kubeconfig=./local/admin-cluster1.conf --install cert-manager \
    oci://dp.apps.rancher.io/charts/cert-manager \
    -n cert-manager \
    --timeout=5m \
    --set crds.enabled=true \
    --set 'global.imagePullSecrets[0].name'=application-collection

  Log "\___Waiting for cert-manager resources to be ready.."
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

  Log "\___Creating cert-manager ClusterIssuer.selfsigned-issuer.."
  kubectl --kubeconfig=./local/admin-cluster1.conf apply -f ./local/cluster1-selfsigned-issuer.yaml
  kubectl --kubeconfig=./local/admin-cluster1.conf wait --for=condition=Ready clusterissuer --all --timeout=300s
}


#
function gensuseobservabilityvalues
{
  Log "function gensuseobservabilityvalues:"

  Log "\___Adding suse-observability helm repo.."
  helm repo add suse-observability https://charts.rancher.com/server-charts/prime/suse-observability
  helm repo update

  # generate values using template
  Log "\___Generating suse-observability helm values using helm template.."
  helm template suse-observability/suse-observability-values \
    --output-dir ./local/ \
    --set license="$OBS_LICENSE" \
    --set baseUrl="https://$OBS_HOSTNAME" \
    --set adminPassword="$OBS_ADMIN_PWD" \
    --set sizing.profile="trial" 

  # Add values for ingress
  Log "\___Creating extra helm values for ingress and opentelemetry.."
  cat << EOF >./local/suse-observability-values/templates/ingress_values.yaml
---
# SUSE Observability ingress helm chart values
ingress:
  annotations: {
    kubernetes.io/ingress.class: nginx,
    cert-manager.io/cluster-issuer: selfsigned-issuer
  }
  enabled: true
  path: /
  hosts:
    - host: $OBS_HOSTNAME
  tls:
    - secretName: suse-obs-tls-secret
      hosts:
        - $OBS_HOSTNAME
EOF

    # Add values for opentelemetry
    cat << OTEOF >./local/suse-observability-values/templates/otel_values.yaml
opentelemetry:
  enabled: true

opentelemetry-collector:
  extraEnvsFrom:
    - secretRef:
        name: open-telemetry-collector
  
  config:
    receivers:
      otlp:
        protocols:
          grpc:
            endpoint: 0.0.0.0:4317
          http:
            endpoint: 0.0.0.0:4318

    extensions:
      # Use the API key from the env for authentication
      bearertokenauth:
        scheme: SUSEObservability
        token: "\${env:API_KEY}"

  ingress:
    enabled: true
    ingressClassName: nginx
    annotations:
      nginx.ingress.kubernetes.io/proxy-body-size: "50m"
      nginx.ingress.kubernetes.io/backend-protocol: GRPC
      #cert-manager.io/cluster-issuer: selfsigned-issuer
    hosts:
      - host: otlp-$OBS_HOSTNAME
        paths:
          - path: /
            pathType: Prefix
            port: 4317
    #tls:
      #- hosts:
      #    - otlp-$OBS_HOSTNAME
      #  secretName: otlp-tls-secret

    additionalIngresses:
      - name: otlp-http
        annotations:
          nginx.ingress.kubernetes.io/proxy-body-size: "50m"
        hosts:
          - host: otlp-http-$OBS_HOSTNAME
            paths:
              - path: /
                pathType: Prefix
                port: 4318
        #tls:
---
OTEOF

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

  Log "\___Creating suse-observability namespace.."
  kubectl --kubeconfig=./local/admin-cluster1.conf create namespace suse-observability

  Log "\___Creating suse-observability.open-telemetry-collector secret.."
  kubectl --kubeconfig=./local/admin-cluster1.conf create secret generic open-telemetry-collector \
    --namespace suse-observability \
    --from-literal=API_KEY="$OBS_API_KEY"

  Log "\___Installing suse-observability/suse-observability helm chart.."
  helm --kubeconfig=./local/admin-cluster1.conf upgrade \
    --install obs suse-observability/suse-observability \
    --namespace suse-observability --create-namespace \
    --values ./local/suse-observability-values/templates/baseConfig_values.yaml \
    --values ./local/suse-observability-values/templates/sizing_values.yaml \
    --values ./local/suse-observability-values/templates/ingress_values.yaml \
    --values ./local/suse-observability-values/templates/otel_values.yaml \
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

# Obtain Obs API-KEY from baseConfig_valuses
OBS_API_KEY=`cat ./local/suse-observability-values/templates/baseConfig_values.yaml  | grep --color=never key | head -1 | awk '{print $2}' | sed 's/\"//g'`
echo $OBS_API_KEY > ./local/obs-apikey.txt
echo OBS_API_KEY: $OBS_API_KEY

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
