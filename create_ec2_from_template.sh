#!/bin/bash
echo "Launching EC2 instance using Launch Template lt-0e1d3b0b3f6fe9384"
# Variables (modify region if required)
REGION="ap-south-1"
LAUNCH_TEMPLATE_ID="lt-0e1d3b0b3f6fe9384"
echo "AWS Region: $REGION"
echo "Launch Template: $LAUNCH_TEMPLATE_ID"
# Run AWS CLI
instance_id=$(aws ec2 run-instances \
    --launch-template LaunchTemplateId=$LAUNCH_TEMPLATE_ID \
    --region $REGION \
    --query "Instances[0].InstanceId" \
    --output text)
if [ $? -ne 0 ]; then
    echo "EC2 Launch Failed."
    exit 1
fi
echo "EC2 Launched Successfully!"
echo "Instance ID: $instance_id"
# Optional: Tag the instance
aws ec2 create-tags \
    --resources $instance_id \
    --tags Key=Name,Value=Jenkins-Launched-Instance \
    --region $REGION
echo "Tag applied to instance: Jenkins-Launched-Instance"
#End

