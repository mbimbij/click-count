#!/bin/bash

if [[ -z $5 ]]; then
  echo -e "usage:\n./create-environment.sh \$APPLICATION_NAME \$CFN_S3_BUCKET_NAME \$BASTION_HOST_AMI_ID \$ENVIRONMENT \$STACK_NAME"
  exit 1
fi

APPLICATION_NAME=$1
CFN_S3_BUCKET_NAME=$2
BASTION_HOST_AMI_ID=$3
ENVIRONMENT=$4
STACK_NAME=$5

echo -e ""

echo -e "##############################################################################"
echo -e "creating environment $ENVIRONMENT"
echo -e "##############################################################################"

APPLICATION_AMI_ID=$(aws ec2 describe-images --owners self --query "Images[?Name=='$APPLICATION_NAME'].ImageId" --output text)
aws cloudformation package --template-file ec2-environment.yml --output-template ec2-environment-$ENVIRONMENT-packaged.yml --s3-bucket $CFN_S3_BUCKET_NAME
jq ". + [{\"ParameterKey\": \"BastionHostAmiId\", \"ParameterValue\": \"$BASTION_HOST_AMI_ID\"},{\"ParameterKey\": \"ApplicationAmiId\", \"ParameterValue\": \"$APPLICATION_AMI_ID\"},{\"ParameterKey\": \"ApplicationName\", \"ParameterValue\": \"$APPLICATION_NAME\"}]" $ENVIRONMENT.json > $ENVIRONMENT-processed.json
aws cloudformation deploy --stack-name $STACK_NAME --template-file ec2-environment-$ENVIRONMENT-packaged.yml --parameter-overrides file://$ENVIRONMENT-processed.json --capabilities CAPABILITY_NAMED_IAM
rm $ENVIRONMENT-processed.json
rm ec2-environment-$ENVIRONMENT-packaged.yml