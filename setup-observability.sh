#!/bin/bash

source ./utils/utils.sh

LogStarted "=====================================> Provisioning cluster1 infra via terraform.."

cd tf
cp cluster1/* .
terraform apply -auto-approve
cd ..

Log "sleeping to wait for instances to initialise.."
sleep 10
LogElapsedDuration


LogStarted "=====================================> Calling subscripts to install cluster1.."

Log "===========================> cluster1: installing RKE2 cluster.."
bash cluster1/01-cluster1-rke2.sh
LogElapsedDuration

Log "===========================> cluster1: importing to rancher-manager.."
bash cluster1/02-cluster1-register.sh
LogElapsedDuration

Log "===========================> cluster1: installing longhorn.."
bash cluster1/03-cluster1-longhorn.sh
LogElapsedDuration

Log "===========================> cluster1: installing suse observability.."
bash cluster1/04-cluster1-observavbility.sh
LogElapsedDuration

Log "===========================> cluster1: post install configuring suse observability.."
bash cluster1/05-cluster1-obs-config.sh
LogElapsedDuration

# --------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
