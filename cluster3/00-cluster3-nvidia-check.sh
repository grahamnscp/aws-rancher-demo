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

Log "Checking agent nodes.."
for ((i=1; i<=$NUM_AGENTS; i++))
do
  checkagentx $i
done

LogCompleted "Done."
# -------------------------------------------------------------------------------------

# tidy up
exit 0
