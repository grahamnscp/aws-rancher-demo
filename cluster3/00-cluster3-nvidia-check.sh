#!/bin/bash

source ./params.sh
source ./utils/utils.sh
source cluster3/load-tf-output-cluster3.sh

#--------------------------------------------------------------------------------
# functions:

function checkagentx
{
  AGENTNUM=$1

  Log "function checkagent: for agent $AGENTNUM"

  AAGENTIP=${AGENT_PUBLIC_IP[$AGENTNUM]}
  AAGENTNAME=${AGENT_NAME[$AGENTNUM]}
  AAGENTN=$(echo $AAGENTNAME | cut -d. -f1)

  ssh $SSH_OPTS ${SSH_USERNAME}@${AAGENTIP} "sudo lsmod | grep nvidia"
  ssh $SSH_OPTS ${SSH_USERNAME}@${AAGENTIP} "sudo nvidia-smi"
}

# -------------------------------------------------------------------------------------
# Main
#
Log "Checking cluster3 agent nodes ready.."
Log "agents node count: $NUM_AGENTS"

for ((node=1; node<=$NUM_AGENTS; node++))
do
  ANODEIP=${AGENT_PUBLIC_IP[$node]}
  ANODENAME=${AGENT_NAME[$node]}
  ANODEN=$(echo $ANODENAME | cut -d. -f1)

  Log "\_Checking $ANODEN is configured.."
  while true
  do
    CONFIGRAN=`ssh $SSH_OPTS ${SSH_USERNAME}@${ANODEIP} "sudo ls -a /root/.suse-fb-config.ran 2>/dev/null | wc -l"`
    if [ "$CONFIGRAN" != "1" ]
    then
      echo -n "."
      sleep 10
      continue
    else
      checkagentx $node
    fi
    break
  done
done

LogCompleted "Done."
# -------------------------------------------------------------------------------------

# tidy up
exit 0
