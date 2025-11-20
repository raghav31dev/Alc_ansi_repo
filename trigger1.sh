#!/bin/bash

echo "🚀 Launching EC2 instance using Launch Template lt-0e1d3b0b3f6fe9384"

# ================================
# Variables
# ================================
REGION="ap-south-1"
LAUNCH_TEMPLATE_ID="lt-0e1d3b0b3f6fe9384"

INVENTORY_FILE="/home/jenkins/ansible/ansi.inv"
GROUP_NAME="aws_nodes"
NEW_IP_FILE="/home/jenkins/ansible/new_instance_ip.txt"

echo "AWS Region: $REGION"
echo "Launch Template: $LAUNCH_TEMPLATE_ID"

# ================================
# 1️⃣ Launch the EC2 instance
# ================================
instance_id=$(aws ec2 run-instances \
    --launch-template LaunchTemplateId=$LAUNCH_TEMPLATE_ID \
    --region $REGION \
    --query "Instances[0].InstanceId" \
    --output text)

if [ $? -ne 0 ] || [ "$instance_id" = "None" ]; then
    echo "❌ EC2 Launch Failed."
    exit 1
fi

echo "✅ EC2 Launched Successfully! Instance ID: $instance_id"


# ================================
# 2️⃣ Wait for instance to be READY
# ================================
echo "⏳ Waiting for instance to enter 'running' state..."
aws ec2 wait instance-running --instance-ids "$instance_id" --region "$REGION"
echo "✅ Instance is running!"


# ================================
# 3️⃣ Fetch the Public IP
# ================================
echo "🔍 Fetching Public IP..."
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $instance_id \
    --region $REGION \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" = "None" ]; then
    echo "❌ Could not fetch Public IP."
    exit 1
fi

echo "🌐 Public IP: $PUBLIC_IP"


# ================================
# 4️⃣ Ensure inventory file contains the group
# ================================
if ! grep -q "^\[$GROUP_NAME\]" "$INVENTORY_FILE"; then
    echo "📌 Group [$GROUP_NAME] not found — adding it."
    echo -e "\n[$GROUP_NAME]" >> "$INVENTORY_FILE"
fi


# ================================
# 5️⃣ Add new host under group
# ================================
echo "➕ Adding new host $PUBLIC_IP to inventory..."

# Avoid duplicate entries
if grep -q "$PUBLIC_IP" "$INVENTORY_FILE"; then
    echo "⚠️ IP already exists in inventory. Skipping adding."
else
    sed -i "/^\[$GROUP_NAME\]/a $PUBLIC_IP ansible_user=ec2-user ansible_ssh_common_args='-o StrictHostKeyChecking=no'" "$INVENTORY_FILE"
    echo "✅ Added $PUBLIC_IP to $INVENTORY_FILE"
fi


# ================================
# 6️⃣ Save IP for next Ansible Trigger
# ================================
echo "$PUBLIC_IP" > "$NEW_IP_FILE"
echo "📁 Saved new instance IP for next trigger: $NEW_IP_FILE"


# ================================
# 7️⃣ Apply Name Tag (Optional)
# ================================
aws ec2 create-tags \
    --resources "$instance_id" \
    --tags Key=Name,Value=Jenkins-Launched-Instance \
    --region "$REGION"

echo "🏷️ Name Tag applied: Jenkins-Launched-Instance"


echo "🎉 Script Completed Successfully!"
