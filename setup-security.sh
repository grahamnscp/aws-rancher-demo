#!/bin/bash

source ./utils.sh

LogStarted "=====================================> Provisioning cluster2 infra via terraform.."

cd tf
cp cluster2/* .
terraform apply -auto-approve
cd ..

sleep 10
LogElapsedDuration

LogStarted "=====================================> Calling subscripts to install cluster2.."

Log "===========================> cluster2: installing RKE2 cluster.."
bash 08-cluster2-rke2.sh
LogElapsedDuration

Log "===========================> cluster2: importing to rancher-manager.."
bash 09-cluster2-register.sh

Log "===========================> cluster2: preparing for suse-security installion.."
bash 10-cluster2-suse-security-pre.sh

# --------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
