#!/bin/bash

if [[ -z $1 ]]; then
  echo -e "usage:\n./delete-stack-wait-termination.sh \$STACK_NAME"
  exit 1
fi

cd "$(dirname "$0")" || exit 255
STACK_NAME=$1

echo -e "##############################################################################"
echo -e "deleting stack $STACK_NAME"
echo -e "##############################################################################"

S3_BUCKETS=$(aws cloudformation describe-stack-resources --stack-name $STACK_NAME --query "StackResources[?ResourceType=='AWS::S3::Bucket'].PhysicalResourceId" --output text)
for S3_BUCKET in $S3_BUCKETS; do
  echo -e "## force deleting S3 bucket $S3_BUCKET for stack $STACK_NAME"
  aws s3 rb s3://$S3_BUCKET --force
done

ECR_REPOS=$(aws cloudformation describe-stack-resources --stack-name $STACK_NAME --query "StackResources[?ResourceType=='AWS::ECR::Repository'].PhysicalResourceId" --output text)
for ECR_REPO in $ECR_REPOS; do
  echo -e "## force deleting ecr repository $ECR_REPO for stack $STACK_NAME"
  ./empty-ecr-repository.sh $ECR_REPO
done

aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME
