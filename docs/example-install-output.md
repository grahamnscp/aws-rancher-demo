# Example Install Output

## Infra deployment via Terraform
```
$ cd tf
$ terraform apply -auto-approve
…
Apply complete! Resources: 28 added, 0 changed, 0 destroyed.

Outputs:

domainname = "demo.suselabs.net"
ran-instance-names = [
  [
    "cluster1-ran1.demo.suselabs.net",
    "cluster1-ran2.demo.suselabs.net",
    "cluster1-ran3.demo.suselabs.net",
  ],
]
ran-instance-private-ips = [
  [
    "172.20.1.95",
    "172.20.1.155",
    "172.20.1.150",
  ],
]
ran-instance-public-eips = [
  [
    "54.225.73.102",
    "44.206.173.186",
    "34.227.34.172",
  ],
]

$ cd ..
```

## Clean local directory from any previous run
```
$ ./00-clean-local-dir
```

## RKE2 cluster install
```
$ ./01-install-rke2.sh

[2024-08-20 11:23:26 INFO] Collecting terraform output values..
cluster1-ran1.demo.suselabs.net 54.225.73.102 172.20.1.95
cluster1-ran2.demo.suselabs.net 44.206.173.186 172.20.1.155
cluster1-ran3.demo.suselabs.net 34.227.34.172 172.20.1.150

[2024-08-20 11:23:40 STARTED] Installing initial RKE2 node (HOST: cluster1-ran1.demo.suselabs.net IP: 54.225.73.102 172.20.1.95)..
[2024-08-20 11:23:40 INFO] \__Creating cluster config.yaml..
Warning: Permanently added '54.225.73.102' (ED25519) to the list of known hosts.
rke2-config.yaml                                                                                                                       100%  254     3.1KB/s   00:00
[2024-08-20 11:23:44 INFO] \__Installing RKE2 (ran1)..
Created symlink /etc/systemd/system/multi-user.target.wants/rke2-server.service → /usr/local/lib/systemd/system/rke2-server.service.
[2024-08-20 11:23:49 INFO] \__Starting rke2-server.service..
[2024-08-20 11:24:45 INFO] \__Waiting for kubeconfig file to be created..
Cluster is now configured..
[2024-08-20 11:24:46 INFO] \__Downloading kube admin.conf locally..
admin.conf                                                                                                                             100% 2973    18.2KB/s   00:00
[2024-08-20 11:24:52 INFO] \__adding kubectl link to bin..
[2024-08-20 11:24:56 DURATION] 1 minutes and 30 seconds elapsed.
[2024-08-20 11:24:56 INFO] function rke2nodewait: for node 1
[2024-08-20 11:24:56 INFO] \_Waiting for RKE2 cluster node (54.225.73.102) to be Ready..
1.1.0
[2024-08-20 11:25:20 INFO]  \__RKE2 cluster nodes are Ready:
NAME            STATUS   ROLES                       AGE   VERSION
cluster1-ran1   Ready    control-plane,etcd,master   43s   v1.28.12+rke2r1
[2024-08-20 11:25:21 INFO] \_Waiting for RKE2 cluster to be fully initialised..
0
[2024-08-20 11:25:52 INFO]  \__RKE2 new cluster node is now initialised.
[2024-08-20 11:25:52 DURATION] 2 minutes and 26 seconds elapsed.

[2024-08-20 11:25:52 STARTED] Installing other RKE2 nodes..

[2024-08-20 11:25:52 INFO] function rke2joinnodex: for node 2
[2024-08-20 11:25:52 INFO] \_Joining RKE2 cluster node (44.206.173.186)..
[2024-08-20 11:25:52 INFO] \__Creating RKE2 join config.yaml..
Warning: Permanently added '44.206.173.186' (ED25519) to the list of known hosts.
rke2-join-config.yaml                                                                                                                  100%  287     3.4KB/s   00:00
[2024-08-20 11:25:56 INFO] \__Installing RKE2 (ran2)..
Created symlink /etc/systemd/system/multi-user.target.wants/rke2-server.service → /usr/local/lib/systemd/system/rke2-server.service.
[2024-08-20 11:26:01 INFO] \__Starting rke2-server.service..
[2024-08-20 11:26:51 DURATION] 3 minutes and 25 seconds elapsed.
[2024-08-20 11:26:51 INFO] function rke2nodewait: for node 2
[2024-08-20 11:26:51 INFO] \_Waiting for RKE2 cluster node (44.206.173.186) to be Ready..
1.1.0
[2024-08-20 11:27:13 INFO]  \__RKE2 cluster nodes are Ready:
NAME            STATUS   ROLES                       AGE     VERSION
cluster1-ran1   Ready    control-plane,etcd,master   2m36s   v1.28.12+rke2r1
cluster1-ran2   Ready    control-plane,etcd,master   26s     v1.28.12+rke2r1
[2024-08-20 11:27:14 INFO] \_Waiting for RKE2 cluster to be fully initialised..
0
[2024-08-20 11:27:45 INFO]  \__RKE2 new cluster node is now initialised.
[2024-08-20 11:27:45 DURATION] 4 minutes and 19 seconds elapsed.
[2024-08-20 11:27:45 INFO] function rke2joinnodex: for node 3
[2024-08-20 11:27:45 INFO] \_Joining RKE2 cluster node (34.227.34.172)..
[2024-08-20 11:27:45 INFO] \__Creating RKE2 join config.yaml..
Warning: Permanently added '34.227.34.172' (ED25519) to the list of known hosts.
rke2-join-config.yaml                                                                                                                  100%  287     3.5KB/s   00:00
[2024-08-20 11:27:49 INFO] \__Installing RKE2 (ran3)..
Created symlink /etc/systemd/system/multi-user.target.wants/rke2-server.service → /usr/local/lib/systemd/system/rke2-server.service.
[2024-08-20 11:27:54 INFO] \__Starting rke2-server.service..
[2024-08-20 11:28:42 DURATION] 5 minutes and 16 seconds elapsed.
[2024-08-20 11:28:42 INFO] function rke2nodewait: for node 3
[2024-08-20 11:28:42 INFO] \_Waiting for RKE2 cluster node (34.227.34.172) to be Ready..
0
[2024-08-20 11:28:43 INFO]  \__RKE2 cluster nodes are Ready:
NAME            STATUS   ROLES                       AGE    VERSION
cluster1-ran1   Ready    control-plane,etcd,master   4m5s   v1.28.12+rke2r1
cluster1-ran2   Ready    control-plane,etcd,master   115s   v1.28.12+rke2r1
[2024-08-20 11:28:43 INFO] \_Waiting for RKE2 cluster to be fully initialised..
2.0
[2024-08-20 11:29:25 INFO]  \__RKE2 new cluster node is now initialised.
[2024-08-20 11:29:25 DURATION] 5 minutes and 59 seconds elapsed.
[2024-08-20 11:29:25 COMPLETED] Done.
```

## Check local kubeconfig access
```
$ kubectl --kubeconfig=local/admin.conf get nodes
NAME            STATUS   ROLES                       AGE     VERSION
cluster1-ran1   Ready    control-plane,etcd,master   8m17s   v1.28.12+rke2r1
cluster1-ran2   Ready    control-plane,etcd,master   6m7s    v1.28.12+rke2r1
cluster1-ran3   Ready    control-plane,etcd,master   4m11s   v1.28.12+rke2r1
```

## Rancher Manager install
```
$ ./02-install-rancher.sh
[2024-08-20 11:35:23 INFO] Collecting terraform output values..
cluster1-ran1.demo.suselabs.net 54.225.73.102 172.20.1.95
cluster1-ran2.demo.suselabs.net 44.206.173.186 172.20.1.155
cluster1-ran3.demo.suselabs.net 34.227.34.172 172.20.1.150

[2024-08-20 11:35:37 STARTED] Installing Rancher Manager..
[2024-08-20 11:35:37 INFO] \__Add helm repo jeystack (for cert-manager)..
"jetstack" already exists with the same configuration, skipping
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "rancher-prime" chart repository
...Successfully got an update from the "neuvector" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "rancher-latest" chart repository
Update Complete. ⎈Happy Helming!⎈
[2024-08-20 11:35:38 INFO] \__helm install cert-manager jetstack/cert-manager ..
NAME: cert-manager
LAST DEPLOYED: Tue Aug 20 11:35:39 2024
NAMESPACE: cert-manager
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
cert-manager v1.15.3 has been deployed successfully!

In order to begin issuing certificates, you will need to set up a ClusterIssuer
or Issuer resource (for example, by creating a 'letsencrypt-staging' issuer).

More information on the different types of issuers and how to configure them
can be found in our documentation:

https://cert-manager.io/docs/configuration/

For information on how to configure cert-manager to automatically provision
Certificates for Ingress resources, take a look at the `ingress-shim`
documentation:

https://cert-manager.io/docs/usage/ingress/
[2024-08-20 11:36:03 DURATION] 0 minutes and 40 seconds elapsed.
[2024-08-20 11:36:03 INFO] \__Add helm repo rancher-latest..
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "neuvector" chart repository
...Successfully got an update from the "jetstack" chart repository
...Successfully got an update from the "rancher-latest" chart repository
Update Complete. ⎈Happy Helming!⎈
[2024-08-20 11:36:04 INFO] \__helm install rancher (version=2.9.0)..
NAME: rancher
LAST DEPLOYED: Tue Aug 20 11:36:05 2024
NAMESPACE: cattle-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Rancher Server has been installed.

NOTE: Rancher may take several minutes to fully initialize. Please standby while Certificates are being issued, Containers are started and the Ingress rule comes up.

Check out our docs at https://rancher.com/docs/

If you provided your own bootstrap password during installation, browse to https://rancher.demo.suselabs.net to get started.

If this is the first time you installed Rancher, get started by running this command and clicking the URL it generates:
echo https://rancher.demo.suselabs.net/dashboard/?setup=$(kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}')

To get just the bootstrap password on its own, run:
kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{ "\n" }}'

Happy Containering!
[2024-08-20 11:36:09 INFO] \__Waiting for Rancher Manager to be fully initialised..
3.0
[2024-08-20 11:36:51 INFO]  \__Rancher is now initialised.
[2024-08-20 11:36:51 DURATION] 1 minutes and 28 seconds elapsed.
[2024-08-20 11:36:51 COMPLETED] Done.
```

## helm cli check
```
$ helm list -n cattle-system
NAME           	NAMESPACE    	REVISION	UPDATED                                	STATUS  	CHART                          	APP VERSION
rancher        	cattle-system	1       	2024-08-20 11:36:05.394343 +0100 BST   	deployed	rancher-2.9.0                  	v2.9.0
rancher-webhook	cattle-system	1       	2024-08-20 10:38:31.322061483 +0000 UTC	deployed	rancher-webhook-104.0.0+up0.5.0	0.5.0


$ helm history rancher -n cattle-system
REVISION	UPDATED                 	STATUS  	CHART        	APP VERSION	DESCRIPTION
1       	Tue Aug 20 11:36:05 2024	deployed	rancher-2.9.0	v2.9.0     	Install complete
```
