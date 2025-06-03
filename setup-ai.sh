#!/bin/bash

source ./utils/utils.sh

LogStarted "=====================================> Provisioning cluster3 infra via terraform.."

cd tf
cp cluster3/* .
terraform apply -auto-approve
RET_VAL=$?
cd ..

if [ "$RET_VAL" == "1" ]
then
  echo Terraform failed, exiting..
fi

LogStarted "=====================================> Calling subscripts to install cluster3.."

Log "===========================> cluster3: checking nvidia driver on agent nodes.."
bash cluster3/00-cluster3-nvidia-check.sh
LogElapsedDuration


Log "===========================> cluster3: installing RKE2 cluster.."
bash cluster3/01-cluster3-rke2.sh
LogElapsedDuration

# register with rancher manager
Log "===========================> cluster3: registering existing cluster with rancher manager.."
bash cluster3/02-cluster3-register.sh
LogElapsedDuration

# install longhorn
Log "===========================> cluster3: deploying longhorn onto cluster.."
bash cluster3/03-cluster3-longhorn.sh
LogElapsedDuration

# deploy observability receiver on ai cluster (opentelemetry?)
Log "===========================> cluster3: deploying ai observability for cluster3.."
bash cluster3/04-cluster3-ai-obs.sh
LogElapsedDuration

# cluster config for suse ai
Log "===========================> cluster3: configuring cluster for suse ai.."
bash cluster3/05-cluster3-ai-config.sh
LogElapsedDuration

# deploy suse-ai components
Log "===========================> cluster3: deploying suse ai.."
bash cluster3/06-cluster3-ai-install.sh
LogElapsedDuration

# --------------------------------------

LogCompleted "Done."

# tidy up
exit 0
