#!/bin/bash

source ./utils/utils.sh

LogStarted "=====================================> Provisioning cluster2 infra via terraform.."

cd tf
cp cluster2/* .
terraform apply -auto-approve
cd ..

Log "sleeping to wait for instances to initialise.."
sleep 10
LogElapsedDuration

LogStarted "=====================================> Calling subscripts to install cluster2.."

Log "===========================> cluster2: installing RKE2 cluster.."
bash cluster2/01-cluster2-rke2.sh
LogElapsedDuration

Log "===========================> cluster2: importing to rancher-manager.."
bash cluster2/02-cluster2-register.sh

Log "===========================> cluster2: preparing for suse-security installion.."
bash cluster2/03-cluster2-suse-security-pre.sh

Log "===========================> cluster2: install suse-security.."
# Can demo neuvector install to cluster2 or uncomment to pre-install
echo "${BWhi}*** Now install the neuvector helm chart via rancher UI ***${RCol}"
# note: the UI NeuVector tab will not autheniicate is pre-installed via cli
#bash cluster2/04-cluster2-suse-security.sh

# --------------------------------------
LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
