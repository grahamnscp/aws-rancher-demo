#!/bin/bash

source ./params.sh
source ./utils/utils.sh

# -------------------------------------------------------------------------------------
Log "\_Provisioning kubernetes-v2 stackpack for cluster3.."

AI_CLUSTER_NAME=cluster3
STS_TOKEN=`cat ./local/sts-token.txt`

curl -sk https://$OBS_HOSTNAME/api/stackpack/kubernetes-v2/provision \
     -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: ApiToken $STS_TOKEN" \
     -d "{\"kubernetes_cluster_name\": \"$AI_CLUSTER_NAME\"}"
echo

# -------------------------------------------------------------------------------------
# Add local receiver agent on cluster3

# pause for stackpacks to deploy fully
sleep 120

Log "\_Installing suse-observability agent on $AI_CLUSTER_NAME.."

OBS_API_KEY=`cat ./local/obs-apikey.txt`

# install observability-agent - details via obs UI adding cluster with name $AI_CLUSTER_NAME
helm --kubeconfig=./local/admin-cluster3.conf upgrade --install suse-observability-agent suse-observability/suse-observability-agent \
     --namespace suse-observability --create-namespace \
     --set-string 'stackstate.apiKey'="$OBS_API_KEY" \
     --set-string 'stackstate.cluster.name'="$AI_CLUSTER_NAME" \
     --set-string 'stackstate.url'="https://$OBS_HOSTNAME/receiver/stsAgent" \
     --set 'nodeAgent.skipKubeletTLSVerify'=true \
     --set-string 'global.skipSslValidation'=true

Log "\__Waiting for suse-observability agent on $AI_CLUSTER_NAME to be Ready.."
kubectl --kubeconfig=./local/admin-cluster3.conf wait pods -n suse-observability -l app.kubernetes.io/instance=suse-observability-agent --for condition=Ready --timeout=300s


# -------------------------------------------------------------------------------------
# OpenTel setup on AI cluster

Log "\_Configure OpenTelemetry Collector.."

Log "\__Creating observability namespace.."
kubectl --kubeconfig=./local/admin-cluster3.conf create namespace observability

Log "\__Creating SUSE Observability API_KEY secret.."
kubectl --kubeconfig=./local/admin-cluster3.conf create secret generic open-telemetry-collector --namespace observability --from-literal=API_KEY="$OBS_API_KEY"

Log "\__Authenticating local helm cli to SUSE Application Collection registry.."
helm registry login dp.apps.rancher.io/charts -u $APPCOL_USER -p $APPCOL_TOKEN

Log "\__Creating a docker-registry secret for SUSE Application Collection.."
kubectl --kubeconfig=./local/admin-cluster3.conf create secret docker-registry application-collection --docker-server=dp.apps.rancher.io --docker-username=$APPCOL_USER --docker-password=$APPCOL_TOKEN -n observability

cat << OTELVEOF >./local/cluster3-otel-values.yaml
global:
  imagePullSecrets:
  - application-collection
extraEnvsFrom:
  - secretRef:
      name: open-telemetry-collector
mode: deployment
ports:
  metrics:
    enabled: true
presets:
  kubernetesAttributes:
    enabled: true
    extractAllPodLabels: true
config:
  receivers:
    prometheus:
      config:
        scrape_configs:
        - job_name: 'gpu-metrics'
          scrape_interval: 10s
          scheme: http
          kubernetes_sd_configs:
            - role: endpoints
              namespaces:
                names:
                - gpu-operator
  exporters:
    otlp:
      endpoint: https://oltp-${OBS_HOSTNAME}:4317
      headers:
        Authorization: "SUSEObservability \${env:API_KEY}"
      tls:
        insecure: true
  processors:
    tail_sampling:
      decision_wait: 10s
      policies:
      - name: rate-limited-composite
        type: composite
        composite:
          max_total_spans_per_second: 500
          policy_order: [errors, slow-traces, rest]
          composite_sub_policy:
          - name: errors
            type: status_code
            status_code:
              status_codes: [ ERROR ]
          - name: slow-traces
            type: latency
            latency:
              threshold_ms: 1000
          - name: rest
            type: always_sample
          rate_allocation:
          - policy: errors
            percent: 33
          - policy: slow-traces
            percent: 33
          - policy: rest
            percent: 34
    resource:
      attributes:
      - key: k8s.cluster.name
        action: upsert
        value: $AI_CLUSTER_NAME
      - key: service.instance.id
        from_attribute: k8s.pod.uid
        action: insert
    filter/dropMissingK8sAttributes:
      error_mode: ignore
      traces:
        span:
          - resource.attributes["k8s.node.name"] == nil
          - resource.attributes["k8s.pod.uid"] == nil
          - resource.attributes["k8s.namespace.name"] == nil
          - resource.attributes["k8s.pod.name"] == nil
  connectors:
    spanmetrics:
      metrics_expiration: 5m
      namespace: otel_span
    routing/traces:
      error_mode: ignore
      table:
      - statement: route()
        pipelines: [traces/sampling, traces/spanmetrics]
  service:
    extensions:
      - health_check
    pipelines:
      traces:
        receivers: [otlp, jaeger]
        processors: [filter/dropMissingK8sAttributes, memory_limiter, resource]
        exporters: [routing/traces]
      traces/spanmetrics:
        receivers: [routing/traces]
        processors: []
        exporters: [spanmetrics]
      traces/sampling:
        receivers: [routing/traces]
        processors: [tail_sampling, batch]
        exporters: [debug, otlp]
      metrics:
        receivers: [otlp, spanmetrics, prometheus]
        processors: [memory_limiter, resource, batch]
        exporters: [debug, otlp]
OTELVEOF

Log "\__Installing opentelemetry-collector helm chart on $AI_CLUSTER_NAME.."
helm upgrade --kubeconfig=./local/admin-cluster3.conf --install opentelemetry-collector \
  oci://dp.apps.rancher.io/charts/opentelemetry-collector \
  -n observability \
  -f ./local/cluster3-otel-values.yaml


# ----------------------------
# Add custom rbac for opentelemetry-collector

Log "\_Loading gpu-operator rbac for opentelemetry-collector into cluster3.."

cat <<RBACEOF | kubectl --kubeconfig=./local/admin-cluster3.conf apply -f -  > /dev/null 2>&1
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: suse-observability-otel-scraper
  namespace: observability
rules:
  - apiGroups: [""]
    resources: ["namespaces", "services", "endpoints"]
    verbs: ["get", "watch", "list"]
  - apiGroups: ["apps"]
    resources: ["replicasets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["extensions"]
    resources: ["replicasets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events", "namespaces", "namespaces/status", "nodes", "nodes/spec", "pods", "pods/status", "replicationcontrollers", "replicationcontrollers/status", "resourcequotas", "services" ]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["apps"]
    resources: ["daemonsets", "deployments", "replicasets", "statefulsets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["extensions"]
    resources: ["daemonsets", "deployments", "replicasets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["batch"]
    resources: ["jobs", "cronjobs"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["autoscaling"]
    resources: ["horizontalpodautoscalers"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["nodes/stats"]
    verbs: ["get", "watch", "list"]
  - apiGroups: ["events.k8s.io"]
    resources: ["events"]
    verbs: ["watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: suse-observability-otel-scraper
subjects:
  - kind: ServiceAccount
    name: opentelemetry-collector
    namespace: observability
roleRef:
  kind: Role
  name: suse-observability-otel-scraper
  apiGroup: rbac.authorization.k8s.io
RBACEOF

# -------------------------------------------------------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
