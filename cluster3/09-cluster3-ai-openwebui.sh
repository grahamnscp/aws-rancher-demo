#!/bin/bash

source ./params.sh
source ./utils/utils.sh

export KUBECONFIG=./local/admin-cluster3.conf

# --------------------------------------------------------------------
LogStarted "Installing suse-ai on cluster3.."

Log "\_Installing open webui.."

Log " \_Creating open webui helm chart values (embedded ollama).."
# pinned: "https://raw.githubusercontent.com/SUSE/suse-ai-observability-extension/refs/tags/v1.5.0/integrations/oi-filter/suse_ai_filter.py"
#         "https://raw.githubusercontent.com/SUSE/suse-ai-observability-extension/refs/tags/v1.5.0/integrations/oi-filter/pricing.json"
cat << OWUIEOF >./local/cluster3-owui-values.yaml
global:
  imagePullSecrets:
  - application-collection
image:
  registry: dp.apps.rancher.io
  repository: containers/open-webui
  pullPolicy: IfNotPresent
ollamaUrls:
- http://ollama.suse-ai.svc.cluster.local:11434
persistence:
  enabled: true
  size: 15Gi
  storageClass: longhorn
ollama:
  enabled: false

pipelines:
  enabled: true
  persistence:
    storageClass: longhorn
  extraEnvVars:
    - name: OTEL_SERVICE_NAME
      value: "owui"
    - name: PIPELINES_URLS
      value: "https://raw.githubusercontent.com/SUSE/suse-ai-observability-extension/refs/heads/main/integrations/oi-filter/suse_ai_filter.py"
    - name: PRICING_JSON
      value: "https://raw.githubusercontent.com/SUSE/suse-ai-observability-extension/refs/heads/main/integrations/oi-filter/pricing.json"
    - name: OTEL_EXPORTER_HTTP_OTLP_ENDPOINT
      value: "http://opentelemetry-collector.observability.svc.cluster.local:4318"

ingress:
  enabled: true
  class: ""
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  host: $AI_HOSTNAME
  tls: true

extraEnvVars:
- name: ENV
  value: dev
- name: DEFAULT_MODELS
  value: "gemma:2b"
- name: DEFAULT_USER_ROLE
  value: "user"
- name: WEBUI_NAME
  value: "SUSE AI"
- name: GLOBAL_LOG_LEVEL
  value: INFO
- name: RAG_EMBEDDING_MODEL
  value: "sentence-transformers/all-MiniLM-L6-v2"
- name: VECTOR_DB
  value: "milvus"
- name: MILVUS_URI
  value: http://milvus.suse-ai.svc.cluster.local:19530
- name: RAG_FILE_MAX_SIZE
  value: "300"
- name: CHUNK_SIZE
  value: "1000"
- name: CHUNK_OVERLAP
  value: "200"
- name: OPENBLAS_NUM_THREADS
  value: "1"
- name: OMP_NUM_THREADS
  value: "1"
- name: ENABLE_OTEL
  value: "true"
- name: ENABLE_OTEL_METRICS
  value: "true"
- name: OTEL_SERVICE_NAME
  value: "owui"
- name: OTEL_EXPORTER_HTTP_OTLP_ENDPOINT
  value: "http://opentelemetry-collector.observability.svc.cluster.local:4318"
- name: OTEL_EXPORTER_OTLP_INSECURE
  value: "true"
- name: PIPELINES_URLS
  value: "https://raw.githubusercontent.com/SUSE/suse-ai-observability-extension/refs/heads/main/integrations/oi-filter/suse_ai_filter.py"
- name: PRICING_JSON
  value: "https://raw.githubusercontent.com/SUSE/suse-ai-observability-extension/refs/heads/main/integrations/oi-filter/pricing.json"
- name: OPENAI_API_KEY
  value: "0p3n-w3bu!"
OWUIEOF

Log " \_Installing open-webui.."
helm upgrade --kubeconfig=./local/admin-cluster3.conf \
  --install open-webui oci://dp.apps.rancher.io/charts/open-webui \
  -n suse-ai \
  -f ./local/cluster3-owui-values.yaml \
  --timeout=10m

Log " \_Waiting for deployment open-webui rollout.."
kubectl --kubeconfig=./local/admin-cluster3.conf \
  wait pods -n suse-ai \
  -l app.kubernetes.io/instance=open-webui --for condition=Ready \
  --timeout=300s

Log "\__sleeping for 2 minutes to allow open-webui to initialise.."
sleep 120

# ----------------------------
# post install:
#  https://documentation.suse.com/suse-ai/1.0/html/AI-deployment-intro/index.html#suse-ai-deploy-post
#
#  1. Log in to SUSE AI Open WebUI using the default credentials.
#  2. After you have logged in, update the administrator password for SUSE AI.
#  3. From the available language models, configure the one you prefer. 
#     Optionally, install a custom language model.
#  4. Configure user management with role-base access control (RBAC) as described in 
#     https://documentation.suse.com/suse-ai/1.0/html/openwebui-configuring/index.html#openwebui-managing-user-roles
#  5. Integrate single sign-on authentication manager—such as Okta—with Open WebUI as described in 
#     https://documentation.suse.com/suse-ai/1.0/html/openwebui-configuring/index.html#openwebui-authentication-via-okta.
#  6. Configure retrieval-augmented generation (RAG) to let the model process content relevant to the customer.

# --------------------------------------------------------------------

LogCompleted "Done."

# tidy up
exit 0
