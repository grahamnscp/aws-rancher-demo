#!/bin/bash

source ./utils.sh

LogStarted "=====================================> Provisioning infra via terraform.."

cd tf
cp cluster1/*.tf .
terraform apply -auto-approve
cd ..

sleep 10
LogElapsedDuration


LogStarted "=====================================> Calling subscripts to install cluster1.."

Log "===========================> cluster1: installing RKE2 cluster.."
bash 04-cluster1-rke2.sh
LogElapsedDuration

Log "===========================> cluster1: importing to rancher-manager.."
bash 05-cluster1-register.sh
LogElapsedDuration

Log "===========================> cluster1: installing longhorn.."
bash 06-cluster1-longhorn.sh
LogElapsedDuration

Log "===========================> cluster1: installing suse observability.."
bash 07-cluster1-observavbility.sh
LogElapsedDuration

# --------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
