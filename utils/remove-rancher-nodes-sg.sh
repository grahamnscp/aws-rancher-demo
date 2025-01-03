#/bin/bash

RN_SG=`aws ec2 describe-security-groups --output text --query 'SecurityGroups[].[GroupName,GroupId]' | grep rancher-nodes | awk '{printf "%s:%s\n", $1, $2}'`
echo $RN_SG

FOUND_RN_SG=`echo $RN_SG |grep rancher-nodes | wc -l|sed "s/^[ \t]*//"`
if [ "$FOUND_RN_SG" == "1" ] 
then
  echo "rancher-nodes security group exists; $RN_SG"

  RN_SG_NAME=`echo $RN_SG | awk -F: '{print $1}'` 
  RN_SG_ID=`echo $RN_SG | awk -F: '{print $2}'` 

  #echo delete security group by name $RN_SG_NAME
  #aws ec2 delete-security-group --group-name $RN_SG_NAME

  echo delete security group by id $RN_SG_ID
  aws ec2 delete-security-group --group-id $RN_SG_ID

else
  echo "rancher-nodes security group not found (count=$FOUND_RN_SG)"
fi

