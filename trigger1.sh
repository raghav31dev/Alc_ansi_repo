#!/bin/bash

echo "Launching EC2 instance using Launch Template lt-0e1d3b0b3f6fe9384"

# Variables
REGION="ap-south-1"
LAUNCH_TEMPLATE_ID="lt-0e1d3b0b3f6fe9384"
INVENTORY_FILE="/home/jenkins/ansible/ansi.inv"
GROUP_NAME="aws_nodes"   # <-- change if needed

echo "AWS Region: $REGION"
echo "Launch Template: $LAUNCH_TEMPLATE_ID"

# 1️⃣ Launch EC2 instance
instance_id=$(aws ec2 run-instances \
    --launch-template LaunchTemplateId=$LAUNCH_TEMPLATE_ID \
    --region $REGION \
    --query "Instances[0].InstanceId" \
    --output text)

if [ $? -ne 0 ]; then
    echo "❌ EC2 Launch Failed."
    exit 1
fi

echo "✅ EC2 Launched Successfully! Instance ID: $instance_id"


# 2️⃣ Wait for instance to enter running state
echo "⏳ Waiting for instance to enter 'running' state..."
aws ec2 wait instance-running --instance-ids $instance_id --region $REGION
echo "✅ Instance is running!"


# 3️⃣ Fetch the Public IP of the instance
echo "🔍 Fetching Public IP..."
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $instance_id \
    --region $REGION \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

echo "🌐 Public IP: $PUBLIC_IP"


# 4️⃣ Ensure inventory file contains group header
if ! grep -q "\[$GROUP_NAME\]" "$INVENTORY_FILE"; then
    echo "[$GROUP_NAME]" >> $INVENTORY_FILE
fi

# 5️⃣ Add the new instance IP under the group
echo "➕ Adding $PUBLIC_IP to $INVENTORY_FILE"
sed -i "/\[$GROUP_NAME\]/a $PUBLIC_IP" $INVENTORY_FILE

echo "✅ Inventory updated: $INVENTORY_FILE"
echo "   Added host: $PUBLIC_IP"


# 6️⃣ Apply Name tag (optional but good practice)
aws ec2 create-tags \
    --resources $instance_id \
    --tags Key=Name,Value=Jenkins-Launched-Instance \
    --region $REGION

echo "🏷️ Tag applied: Jenkins-Launched-Instance"

echo "🎉 Script complete!"
