# Downstream demo clusterx script

## What are they?
This repo contains a number of downstream clusters labeled clusterx  

These clusters are used to showcase various component parts for the SUSE Rancher Prime suite.

* cluster1 - SUSE Observability (nee StackState)
* cluster2 - SUSE Security (nee NeuVector)
* cluster3 - SUSE AI

Each downstream cluster has terraform infra in a subdirectory under tf/  
There are corresponding clusterx subdirectories for the component deployment scripts  

The idea is that you don't need to deploy everything every time, so can pick and chose depending on what you want to test or demo etc.  

The downstream clusters are all installed as freestanding RKE2 clusters and then added to Rancher Manager using Import Existing.

The downstream scripts are designed to be called from the top-level directory, ex ./cluster1/load-tf-output-cluster1.sh  
There are wrapper scripts to install all cluster subscripts, setup-xyx, run setup-rancher first, if looking to install suse ai this sends data to suse observability so run setup-observability before setup-ai etc

## Notes
* they all need local kubectl and helm commands on your client system (laptop, desktop etc)
* cluster1, cluster2, cluster3 all use the rancher cli, so have that pre-installed on your client system
* cluster1 uses the stacktate cli called sls, pre-install this, the connection token is updated by the scripts
* cluster1 uses a go binary (shipped built on arm64 macos in repo) to download the sts token using username/password


