#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0097d14ad3a0baf5f" # replace with your SG ID
#ZONE_ID="Z0948150OFPSYTNVYZOY" # replace with your ID
#DOMAIN_NAME="daws86s.fun"

for instance in $@ # mongodb redis mysql
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)

    # Get Private IP
    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
         # mongodb.daws86s.fun
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        
    fi

    echo "$instance: $IP"