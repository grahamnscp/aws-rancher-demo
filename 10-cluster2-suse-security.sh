#!/bin/bash

source ./params.sh
source ./utils.sh
source ./load-tf-output-cluster2.sh
SEC_HOSTNAME=sec.$DOMAINNAME

# -------------------------------------------------------------------------------------
# functions:

#
function createsusesecurityvalues
{
  cat <<EOF > ./local/suse-security-values-base.yaml
bootstrapPassword: $SEC_ADMIN_PWD
manager:
  ingress:
    enabled: true
    host: $SEC_HOSTNAME
    path: /
    annotations:
      nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    tls: false
EOF

  cat <<EOF > ./local/suse-security-values-rancher.yaml
admissionwebhook:
  type: ClusterIP
autoGenerateCert: true
bootstrapPassword: $SEC_ADMIN_PWD
bottlerocket:
  enabled: false
  runtimePath: /run/dockershim.sock
containerd:
  enabled: false
  path: /var/run/containerd/containerd.sock
controller:
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - podAffinityTerm:
            labelSelector:
              matchExpressions:
                - key: app
                  operator: In
                  values:
                    - neuvector-controller-pod
            topologyKey: kubernetes.io/hostname
          weight: 100
  annotations: {}
  apisvc:
    annotations: {}
    route:
      enabled: false
      host: null
      termination: passthrough
      tls: null
    type: null
  azureFileShare:
    enabled: false
    secretName: null
    shareName: null
  certificate:
    keyFile: tls.key
    pemFile: tls.pem
    secret: ''
  certupgrader:
    env: []
    imagePullPolicy: IfNotPresent
    nodeSelector: {}
    podAnnotations: {}
    podLabels: {}
    priorityClassName: null
    runAsUser: null
    schedule: ''
    timeout: 3600
  configmap:
    data: null
    enabled: false
  disruptionbudget: 0
  enabled: true
  env: []
  federation:
    managedsvc:
      annotations: {}
      clusterIP: null
      externalTrafficPolicy: null
      ingress:
        annotations:
          nginx.ingress.kubernetes.io/backend-protocol: HTTPS
        enabled: false
        host: null
        ingressClassName: ''
        path: /
        secretName: null
        tls: false
      internalTrafficPolicy: null
      loadBalancerIP: null
      nodePort: null
      route:
        enabled: false
        host: null
        termination: passthrough
        tls: null
      type: null
    mastersvc:
      annotations: {}
      clusterIP: null
      externalTrafficPolicy: null
      ingress:
        annotations:
          nginx.ingress.kubernetes.io/backend-protocol: HTTPS
        enabled: false
        host: null
        ingressClassName: ''
        path: /
        secretName: null
        tls: false
      internalTrafficPolicy: null
      loadBalancerIP: null
      nodePort: null
      route:
        enabled: false
        host: null
        termination: passthrough
        tls: null
      type: null
  image:
    hash: null
    repository: rancher/mirrored-neuvector-controller
    tag: 5.4.1
  ingress:
    annotations:
      nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    enabled: false
    host: null
    ingressClassName: ''
    path: /
    secretName: null
    tls: false
  internal:
    certificate:
      caFile: ca.crt
      keyFile: tls.key
      pemFile: tls.crt
      secret: ''
  nodeSelector: {}
  podAnnotations: {}
  podLabels: {}
  prime:
    enabled: true
    image:
      hash: null
      repository: rancher/mirrored-neuvector-compliance-config
      tag: latest
  priorityClassName: null
  pvc:
    accessModes:
      - ReadWriteMany
    capacity: null
    enabled: false
    existingClaim: false
    storageClass: null
  ranchersso:
    enabled: true
  replicas: 3
  resources: {}
  schedulerName: null
  searchRegistries: null
  secret:
    data:
      userinitcfg.yaml:
        users:
          - Fullname: admin
            Password: null
            Role: admin
    enabled: false
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
    type: RollingUpdate
  tolerations: []
  topologySpreadConstraints: []
crdwebhook:
  enabled: true
  type: ClusterIP
crdwebhooksvc:
  enabled: true
crio:
  enabled: false
  path: /var/run/crio/crio.sock
cve:
  adapter:
    affinity: {}
    certificate:
      keyFile: tls.key
      pemFile: tls.crt
      secret: ''
    enabled: false
    env: []
    harbor:
      protocol: https
      secretName: null
    image:
      hash: null
      repository: rancher/mirrored-neuvector-registry-adapter
      tag: 0.1.3
    ingress:
      annotations:
        nginx.ingress.kubernetes.io/backend-protocol: HTTPS
      enabled: false
      host: null
      ingressClassName: ''
      path: /
      secretName: null
      tls: false
    internal:
      certificate:
        caFile: ca.crt
        keyFile: tls.key
        pemFile: tls.crt
        secret: ''
    nodeSelector: {}
    podAnnotations: {}
    podLabels: {}
    priorityClassName: null
    resources: {}
    route:
      enabled: true
      host: null
      termination: passthrough
      tls: null
    runAsUser: null
    svc:
      annotations: {}
      loadBalancerIP: null
      type: NodePort
    tolerations: []
  scanner:
    affinity: {}
    dockerPath: ''
    enabled: true
    env: []
    image:
      hash: null
      registry: ''
      repository: rancher/mirrored-neuvector-scanner
      tag: latest
    internal:
      certificate:
        caFile: ca.crt
        keyFile: tls.key
        pemFile: tls.crt
        secret: ''
    nodeSelector: {}
    podAnnotations: {}
    podLabels: {}
    priorityClassName: null
    replicas: 3
    resources: {}
    runAsUser: null
    strategy:
      rollingUpdate:
        maxSurge: 1
        maxUnavailable: 0
      type: RollingUpdate
    tolerations: []
    topologySpreadConstraints: []
  updater:
    cacert: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    enabled: true
    image:
      hash: null
      registry: ''
      repository: rancher/mirrored-neuvector-updater
      tag: latest
    nodeSelector: {}
    podAnnotations: {}
    podLabels: {}
    priorityClassName: null
    resources: {}
    runAsUser: null
    schedule: 0 0 * * *
    secure: false
defaultValidityPeriod: 365
docker:
  path: /var/run/docker.sock
enforcer:
  enabled: true
  env: []
  image:
    hash: null
    repository: rancher/mirrored-neuvector-enforcer
    tag: 5.4.1
  internal:
    certificate:
      caFile: ca.crt
      keyFile: tls.key
      pemFile: tls.crt
      secret: ''
  podAnnotations: {}
  podLabels: {}
  priorityClassName: null
  resources: {}
  tolerations:
    - effect: NoSchedule
      key: node-role.kubernetes.io/master
    - effect: NoSchedule
      key: node-role.kubernetes.io/control-plane
  updateStrategy:
    type: RollingUpdate
global:
  cattle:
    psp:
      enabled: false
    url: null
internal:
  autoGenerateCert: true
  autoRotateCert: false
  certmanager:
    enabled: false
    secretname: neuvector-internal
k3s:
  enabled: false
  runtimePath: /run/k3s/containerd/containerd.sock
leastPrivilege: false
manager:
  affinity: {}
  certificate:
    keyFile: tls.key
    pemFile: tls.pem
    secret: ''
  enabled: true
  env:
    envs: []
    ssl: true
  image:
    hash: null
    repository: rancher/mirrored-neuvector-manager
    tag: 5.4.1
  ingress:
    annotations:
      nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    enabled: true
    host: $SEC_HOSTNAME
    ingressClassName: ''
    path: /
    secretName: null
    tls: false
  nodeSelector: {}
  podAnnotations: {}
  podLabels: {}
  priorityClassName: null
  probes:
    enabled: false
    periodSeconds: 10
    startupFailureThreshold: 30
    timeout: 1
  resources: {}
  route:
    enabled: true
    host: null
    termination: passthrough
    tls: null
  runAsUser: null
  svc:
    annotations: {}
    loadBalancerIP: null
    type: NodePort
  tolerations: []
  topologySpreadConstraints: []
oem: null
openshift: false
rbac: true
registry: docker.io
resources: {}
runtimePath: null
serviceAccount: neuvector
tag: 5.4.1
EOF
}

#
function installsusesecurity
{
  helm --kubeconfig=./local/admin-cluster2.conf upgrade --install neuvector neuvector/core \
       --namespace cattle-neuvector-system \
       -f ./local/suse-security-values-rancher.yaml

  kubectl --kubeconfig=./local/admin-cluster2.conf wait pods -n cattle-neuvector-system -l app=neuvector-manager-pod --for condition=Ready --timeout=180s
  kubectl --kubeconfig=./local/admin-cluster2.conf wait pods -n cattle-neuvector-system -l app=neuvector-controller-pod --for condition=Ready
  kubectl --kubeconfig=./local/admin-cluster2.conf wait pods -n cattle-neuvector-system -l app=neuvector-enforcer-pod --for condition=Ready
  kubectl --kubeconfig=./local/admin-cluster2.conf wait pods -n cattle-neuvector-system -l app=neuvector-scanner-pod --for condition=Ready
}

# -------------------------------------------------------------------------------------
# Main

LogStarted "Installing SUSE Security to cluster2.."

Log "\__Creating suse-security-values file.."
createsusesecurityvalues

Log "\__Installing suse-security helm chart.."
installsusesecurity

# -------------------------------------------------------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
