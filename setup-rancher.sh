#!/bin/bash

source ./utils/utils.sh

LogStarted "=====================================> Provisioning infra via terraform.."

cd tf
terraform apply -auto-approve
cd ..

Log "sleeping to wait for instances to initialise.."
sleep 10
LogElapsedDuration

LogStarted "=====================================> Calling subscripts to install rancher manager.."

Log "===========================> Cleaning up from previous run.."
bash 00-clean-local-dir

Log "===========================> Installing RKE2 cluster.."
bash 01-install-rke2.sh
LogElapsedDuration

Log "===========================> installing rancher-manager.."
bash 02-install-rancher.sh
LogElapsedDuration

sleep 30

Log "===========================> performing initial rancher-manager configuration.."
bash 03-rancher-config.sh

# --------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
