ifndef APPLICATION_NAME
$(error APPLICATION_NAME is not set)
endif

.IGNORE: s3-bucket

KUBE_PIPELINE_STACK_NAME=$(APPLICATION_NAME)-kube-pipeline
ELASTICACHE_STACK_BASE_NAME=$(APPLICATION_NAME)-elasticache

kube-all:
	$(MAKE) s3-bucket
	- $(MAKE) -j2 kube-cluster-staging kube-cluster-production
	$(MAKE) -j2 kube-environment-staging kube-environment-production
	$(MAKE) kube-pipeline
delete-kube-all:
	- $(MAKE) delete-kube-pipeline
	- $(MAKE) -j2 delete-kube-environment-staging delete-kube-environment-production
	- $(MAKE) -j2 delete-kube-cluster-staging delete-kube-cluster-production
	- $(MAKE) delete-s3-bucket
delete-kube-all-light:
	$(MAKE) -j4 delete-kube-pipeline delete-kube-environment-staging delete-kube-environment-production delete-s3-bucket


kube-cluster-staging:
	$(MAKE) kube-cluster ENVIRONMENT=staging
kube-cluster-production:
	$(MAKE) kube-cluster ENVIRONMENT=production
kube-cluster: requires-environment-set
	envsubst < kubernetes/cluster/cluster-template.yml > kubernetes/cluster/$(ENVIRONMENT)-cluster-processed.yml
	eksctl create cluster -f  kubernetes/cluster/$(ENVIRONMENT)-cluster-processed.yml
	eksctl create iamidentitymapping \
		--cluster $(APPLICATION_NAME)-staging \
		--arn arn:aws:iam::$(AWS_ACCOUNT_ID):role/$(APPLICATION_NAME)-kube-deploy-role \
		--group system:masters \
		--username $(APPLICATION_NAME)-kube-deploy-role
delete-kube-cluster-staging:
	$(MAKE) delete-kube-cluster ENVIRONMENT=staging
delete-kube-cluster-production:
	$(MAKE) delete-kube-cluster ENVIRONMENT=production
delete-kube-cluster: requires-environment-set
	eksctl delete cluster $(APPLICATION_NAME)-$(ENVIRONMENT)


kube-environment-staging:
	$(MAKE) kube-environment ENVIRONMENT=staging
kube-environment-production:
	$(MAKE) kube-environment ENVIRONMENT=production
kube-environment: requires-environment-set s3-bucket
	$(eval KUBE_VPC_ID := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='eksctl-$(APPLICATION_NAME)-$(ENVIRONMENT)-cluster::VPC'].Value" --output text))
	$(eval KUBE_PRIVATE_SUBNET_IDS := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='eksctl-$(APPLICATION_NAME)-$(ENVIRONMENT)-cluster::SubnetsPrivate'].Value" --output text))
	$(eval KUBE_SECURITY_GROUP_ID := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='eksctl-$(APPLICATION_NAME)-$(ENVIRONMENT)-cluster::SharedNodeSecurityGroup'].Value" --output text))
	cd kubernetes && aws cloudformation package --template-file kube-environment.yml --output-template kube-environment-packaged.yml --s3-bucket $(S3_BUCKET_NAME)
	aws cloudformation deploy    \
		--stack-name kube-$(APPLICATION_NAME)-$(ENVIRONMENT)   \
		--template-file kubernetes/kube-environment-packaged.yml    \
		--parameter-overrides  \
			ApplicationName=$(APPLICATION_NAME) \
			Environment=$(ENVIRONMENT) \
			KubeVpcId=$(KUBE_VPC_ID) \
			KubePrivateSubnetIds=$(KUBE_PRIVATE_SUBNET_IDS) \
			KubeNodesSecurityGroupId=$(KUBE_SECURITY_GROUP_ID)
delete-kube-environment-staging:
	$(MAKE) delete-kube-environment ENVIRONMENT=staging
delete-kube-environment-production:
	$(MAKE) delete-kube-environment ENVIRONMENT=production
delete-kube-environment: requires-environment-set
	./stack-deletion/delete-stack-wait-termination.sh kube-$(APPLICATION_NAME)-$(ENVIRONMENT)

kube-pipeline: s3-bucket
	aws cloudformation deploy    \
		--stack-name $(KUBE_PIPELINE_STACK_NAME)   \
		--template-file kubernetes/pipeline/kubernetes-pipeline.yml    \
		--capabilities CAPABILITY_NAMED_IAM   \
		--parameter-overrides     \
		ApplicationName=$(APPLICATION_NAME)   \
		S3Bucket=$(S3_BUCKET_NAME) \
		GithubRepo=$(GITHUB_REPO)   \
		GithubRepoBranch=$(GITHUB_REPO_BRANCH)
delete-kube-pipeline:
	./stack-deletion/delete-stack-wait-termination.sh $(KUBE_PIPELINE_STACK_NAME)
