include infra.env

ifndef APPLICATION_NAME
$(error APPLICATION_NAME is not set)
endif
ifndef AWS_REGION
$(error AWS_REGION is not set)
endif

include make-kubernetes.mk
include make-bucket.mk

SHELL := /bin/bash

AWS_REGION := $(shell aws configure get region)
AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query "Account" --output text)

GITHUB_REPO_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)
$(eval BASE_AMI_ID := $(shell aws ssm get-parameters --names /aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/hvm/ebs-gp2/ami-id --query 'Parameters[0].[Value]' --output text))

S3_BUCKET_NAME=$(AWS_REGION)-$(AWS_ACCOUNT_ID)-$(APPLICATION_NAME)-bucket
S3_BUCKET_STACK_NAME=$(S3_BUCKET_NAME)
STAGING_ENVIRONMENT_STACK_NAME=$(APPLICATION_NAME)-staging-environment
PRODUCTION_ENVIRONMENT_STACK_NAME=$(APPLICATION_NAME)-production-environment
PIPELINE_STACK_NAME=$(APPLICATION_NAME)-pipeline

.PHONY: toto ami pipeline ssh-key-pair s3-bucket

.IGNORE: ami

all:
	$(MAKE) -j3 ami s3-bucket ssh-key-pair
	$(MAKE) -j2 staging-environment production-environment
	$(MAKE) pipeline
requires-environment-set:
	@if [ -z $(ENVIRONMENT) ]; then >&2 echo "ENVIRONMENT is not set"; exit 255; fi
ssh-key-pair:
	./ssh-key-pair/create-ssh-key-pair.sh $(SSH_KEY_NAME) $(SSH_KEY_PATH)
ami:
	cd ami && ./create-ami.sh $(APPLICATION_NAME) $(BASE_AMI_ID) $(AWS_REGION)
staging-environment: ami s3-bucket ssh-key-pair
	cd environment && ./create-environment.sh $(APPLICATION_NAME) $(S3_BUCKET_NAME) $(BASE_AMI_ID) staging $(STAGING_ENVIRONMENT_STACK_NAME)
production-environment: ami s3-bucket ssh-key-pair
	cd environment && ./create-environment.sh $(APPLICATION_NAME) $(S3_BUCKET_NAME) $(BASE_AMI_ID) production $(PRODUCTION_ENVIRONMENT_STACK_NAME)
pipeline:
	aws cloudformation package --template-file pipeline/pipeline.yml --output-template pipeline/pipeline-packaged.yml --s3-bucket $(S3_BUCKET_NAME)
	$(eval STAGING_VPC_ID := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='$(APPLICATION_NAME)::staging::network::VPC'].Value" --output text))
	$(eval STAGING_PRIVATE_SUBNET_IDS := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='$(APPLICATION_NAME)::staging::network::PrivateSubnets'].Value" --output text))
	$(eval STAGING_ENVIRONMENT_DNS := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='$(APPLICATION_NAME)::staging::InstancePrivateDns'].Value" --output text))
	$(eval STAGING_TEST_RUNNER_SECURITY_GROUP_ID := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='$(APPLICATION_NAME)::staging::TestRunnerSecurityGroupId'].Value" --output text))
	$(eval PRODUCTION_VPC_ID := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='$(APPLICATION_NAME)::production::network::VPC'].Value" --output text))
	$(eval PRODUCTION_PRIVATE_SUBNET_IDS := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='$(APPLICATION_NAME)::production::network::PrivateSubnets'].Value" --output text))
	$(eval PRODUCTION_ENVIRONMENT_DNS := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='$(APPLICATION_NAME)::production::InstancePrivateDns'].Value" --output text))
	$(eval PRODUCTION_TEST_RUNNER_SECURITY_GROUP_ID := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='$(APPLICATION_NAME)::production::TestRunnerSecurityGroupId'].Value" --output text))
	aws cloudformation deploy    \
	  --stack-name $(PIPELINE_STACK_NAME)   \
	  --template-file pipeline/pipeline-packaged.yml    \
	  --capabilities CAPABILITY_NAMED_IAM   \
	  --parameter-overrides     \
		ApplicationName=$(APPLICATION_NAME)   \
		S3Bucket=$(S3_BUCKET_NAME) \
		GithubRepo=$(GITHUB_REPO)   \
		GithubRepoBranch=$(GITHUB_REPO_BRANCH) \
		StagingVpcId=$(STAGING_VPC_ID) \
        StagingPrivateSubnetIds=$(STAGING_PRIVATE_SUBNET_IDS) \
        StagingEnvironmentDns=$(STAGING_ENVIRONMENT_DNS) \
        StagingTestRunnerSecurityGroupId=$(STAGING_TEST_RUNNER_SECURITY_GROUP_ID) \
        ProductionVpcId=$(PRODUCTION_VPC_ID) \
		ProductionPrivateSubnetIds=$(PRODUCTION_PRIVATE_SUBNET_IDS) \
		ProductionEnvironmentDns=$(PRODUCTION_ENVIRONMENT_DNS) \
        ProductionTestRunnerSecurityGroupId=$(PRODUCTION_TEST_RUNNER_SECURITY_GROUP_ID)
#        TestRunnerSecurityGroupId='sg-001765d4d50ff2df5'
	rm pipeline/pipeline-packaged.yml


delete-all:
	$(MAKE) delete-pipeline
	$(MAKE) -j2 delete-staging-environment delete-production-environment
	$(MAKE) -j3 delete-ssh-key-pair delete-s3-bucket delete-ami
delete-all-except-ami-and-ssh-key-pair:
	$(MAKE) delete-pipeline
	$(MAKE) -j2 delete-staging-environment delete-production-environment
	$(MAKE) delete-s3-bucket
delete-ami:
	$(eval AMI_ID := $(shell aws ec2 describe-images --owners self --query "Images[?Name=='$(APPLICATION_NAME)'].ImageId" --output text))
	aws ec2 deregister-image --image-id $(AMI_ID)
delete-ssh-key-pair:
	aws ec2 delete-key-pair --key-name $(SSH_KEY_NAME)
delete-staging-environment:
	./stack-deletion/delete-stack-wait-termination.sh $(STAGING_ENVIRONMENT_STACK_NAME)
delete-production-environment:
	./stack-deletion/delete-stack-wait-termination.sh $(PRODUCTION_ENVIRONMENT_STACK_NAME)
delete-pipeline:
	./stack-deletion/delete-stack-wait-termination.sh $(PIPELINE_STACK_NAME)