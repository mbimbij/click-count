ifndef APPLICATION_NAME
$(error APPLICATION_NAME is not set)
endif
include infra.env

SHELL := /bin/bash

AWS_REGION := $(shell aws configure get region)
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query "Account" --output text)

GITHUB_REPO_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
$(eval BASE_AMI_ID := $(shell aws ssm get-parameters --names /aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id --query 'Parameters[0].[Value]' --output text))

S3_BUCKET_NAME=$(AWS_REGION)-$(AWS_ACCOUNT_ID)-$(APPLICATION_NAME)-bucket
S3_BUCKET_STACK_NAME=$(S3_BUCKET_NAME)
STAGING_ENVIRONMENT_STACK_NAME=$(APPLICATION_NAME)-staging-environment

.PHONY: pipeline ssh-key-pair s3-bucket

all:
	$(MAKE) s3-bucket
	$(MAKE) staging-environment
s3-bucket:
	aws cloudformation deploy    \
          --stack-name $(S3_BUCKET_STACK_NAME)   \
          --template-file s3-bucket/s3-bucket.yml   \
          --parameter-overrides     \
            BucketName=$(S3_BUCKET_NAME)
ssh-key-pair:
	./ssh-key-pair/create-ssh-key-pair.sh $(SSH_KEY_NAME) $(SSH_KEY_PATH)
staging-environment: s3-bucket ssh-key-pair
	aws cloudformation package --template-file environment.yml --output-template environment-packaged.yml --s3-bucket $(S3_BUCKET_NAME)
	jq ". + [{\"ParameterKey\": \"AmiId\", \"ParameterValue\": \"$(BASE_AMI_ID)\"}]" staging.json > staging-processed.json
	aws cloudformation deploy --stack-name $(STAGING_ENVIRONMENT_STACK_NAME) --template-file environment-packaged.yml --parameter-overrides file://staging-processed.json
	rm staging-processed.json
	rm environment-packaged.yml

delete-s3-bucket:
	./stack-deletion/delete-stack-wait-termination.sh $(S3_BUCKET_STACK_NAME)
delete-ssh-key-pair:
	aws ec2 delete-key-pair --key-name $(SSH_KEY_NAME)
delete-staging-environment:
	./stack-deletion/delete-stack-wait-termination.sh $(STAGING_ENVIRONMENT_STACK_NAME)
