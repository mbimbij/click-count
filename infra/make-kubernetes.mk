ifndef APPLICATION_NAME
$(error APPLICATION_NAME is not set)
endif

KUBE_PIPELINE_STACK_NAME=$(APPLICATION_NAME)-kube-pipeline
ELASTICACHE_STACK_BASE_NAME=$(APPLICATION_NAME)-elasticache

kube-cluster: requires-environment-set
	envsubst < kubernetes/cluster/cluster-template.yml > kubernetes/cluster/$(ENVIRONMENT)-cluster-processed.yml
	- eksctl create cluster -f  kubernetes/cluster/$(ENVIRONMENT)-cluster-processed.yml
	aws ssm put-parameter \
		--name "/$(APPLICATION_NAME)/$(ENVIRONMENT)/kubernetes/cluster-name" \
		--value "$(APPLICATION_NAME)-$(ENVIRONMENT)" \
		--type "String" \
		--overwrite
	eksctl create iamidentitymapping \
      --cluster $(APPLICATION_NAME)-$(ENVIRONMENT) \
      --arn arn:aws:iam::$(AWS_ACCOUNT_ID):role/$(APPLICATION_NAME)-kube-deploy-role \
      --group system:masters \
      --username $(APPLICATION_NAME)-kube-deploy-role

delete-kube-cluster: requires-environment-set
	eksctl delete cluster $(APPLICATION_NAME)-$(ENVIRONMENT)

elasticache: requires-environment-set
	$(eval VPC_ID := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='eksctl-$(APPLICATION_NAME)-$(ENVIRONMENT)-cluster::VPC'].Value" --output text))
	$(eval PRIVATE_SUBNET_IDS := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='eksctl-$(APPLICATION_NAME)-$(ENVIRONMENT)-cluster::SubnetsPrivate'].Value" --output text))
	$(eval APPLICATION_SECURITY_GROUP_ID := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='eksctl-$(APPLICATION_NAME)-$(ENVIRONMENT)-cluster::ClusterSecurityGroupId'].Value" --output text))
	aws cloudformation deploy    \
		--stack-name $(ELASTICACHE_STACK_BASE_NAME)-$(ENVIRONMENT)   \
		--template-file environment/elasticache/redis-cluster.yml    \
		--parameter-overrides     \
		ApplicationName=$(APPLICATION_NAME)   \
		Environment=$(ENVIRONMENT) \
		VpcId=$(VPC_ID) \
		SubnetIds=$(PRIVATE_SUBNET_IDS) \
		ApplicationSecurityGroupId=$(APPLICATION_SECURITY_GROUP_ID)

kube-pipeline: s3-bucket
	aws cloudformation deploy    \
		--stack-name $(KUBE_PIPELINE_STACK_NAME)   \
		--template-file kubernetes/pipeline/kubernetes-pipeline.yml    \
		--capabilities CAPABILITY_NAMED_IAM   \
		--parameter-overrides     \
		ApplicationName=$(APPLICATION_NAME)   \
		S3Bucket=$(S3_BUCKET_NAME) \
		GithubRepo=$(GITHUB_REPO)   \
		GithubRepoBranch=$(GITHUB_REPO_BRANCH) \

delete-kube-pipeline:
	./stack-deletion/delete-stack-wait-termination.sh $(KUBE_PIPELINE_STACK_NAME)