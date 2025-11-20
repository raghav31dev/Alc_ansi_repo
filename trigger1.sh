#!/bin/bash

echo "Pull complete. Starting EC2 instance creation script..."

REGION="ap-south-1"
LAUNCH_TEMPLATE_ID="lt-0e1d3b0b3f6fe9384"
INVENTORY_FILE="/home/jenkins/ansible/ansi.inv"
GROUP_NAME="aws_nodes"

# Launch instance
echo "Launching EC2 instance..."
instance_id=$(aws ec2 run-instances \
    --launch-template LaunchTemplateId=$LAUNCH_TEMPLATE_ID \
    --region $REGION \
    --query "Instances[0].InstanceId" \
    --output text)

echo "Instance ID: $instance_id"

# Wait for running
echo "Waiting for instance to enter running state..."
aws ec2 wait instance-running --instance-ids $instance_id --region $REGION

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $instance_id \
    --region $REGION \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

# Get AZ
AZ=$(aws ec2 describe-instances \
    --instance-ids $instance_id \
    --region $REGION \
    --query "Reservations[0].Instances[0].Placement.AvailabilityZone" \
    --output text)

echo "Public IP: $PUBLIC_IP"
echo "AZ: $AZ"

# Inject Jenkins SSH key
echo "Injecting Jenkins SSH public key into EC2..."
aws ec2-instance-connect send-ssh-public-key \
    --instance-id $instance_id \
    --instance-os-user ec2-user \
    --availability-zone $AZ \
    --region $REGION \
    --ssh-public-key file:///home/jenkins/.ssh/id_rsa.pub

# Update inventory
echo "Updating inventory..."
if ! grep -q "\[$GROUP_NAME\]" "$INVENTORY_FILE"; then
    echo "[$GROUP_NAME]" >> $INVENTORY_FILE
fi

sed -i "/\[$GROUP_NAME\]/a $PUBLIC_IP ansible_user=ec2-user ansible_ssh_private_key_file=/home/jenkins/.ssh/id_rsa" $INVENTORY_FILE

echo "Inventory updated with: $PUBLIC_IP"
