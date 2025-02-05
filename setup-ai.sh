#!/bin/bash

source ./utils.sh

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

# long sleep for instances agent node instances to reboot and come back up
Log "cluster3: sleeping to wait for instances to install drivers and reboot.."
sleep 360
LogElapsedDuration

LogStarted "=====================================> Calling subscripts to install cluster3.."

Log "===========================> cluster3: installing RKE2 cluster.."
bash 11-cluster3-rke2.sh
LogElapsedDuration

# todo: nvidia operator

# install longhorn
Log "===========================> cluster3: deploying longhorn onto cluster.."
bash 13-cluster3-longhorn.sh
LogElapsedDuration

# register with rancher manager
Log "===========================> cluster3: registering existing cluster with rancher manager.."
bash 12-cluster3-register.sh
LogElapsedDuration

# deploy observability receiver on ai cluster (opentelemetry?)
Log "===========================> cluster3: deploying observability agent for cluster3.."
bash 14-cluster3-obs-agent.sh
LogElapsedDuration

# todo: suse application collection auth
# todo: install suse ai components, db etc..

# --------------------------------------

LogElapsedDuration
LogCompleted "Done."

# tidy up
exit 0
