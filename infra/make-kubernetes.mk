ifndef APPLICATION_NAME
$(error APPLICATION_NAME is not set)
endif

KUBE_PIPELINE_STACK_NAME=$(APPLICATION_NAME)-kube-pipeline
ELASTICACHE_STACK_BASE_NAME=$(APPLICATION_NAME)-elasticache
KUBE_S3_BUCKET_NAME=$(AWS_REGION)-$(AWS_ACCOUNT_ID)-$(APPLICATION_NAME)-kube-bucket
KUBE_S3_BUCKET_STACK_NAME=$(KUBE_S3_BUCKET_NAME)

kube-all:
	$(MAKE) kube-s3-bucket
	$(MAKE) -j2 kube-cluster-staging kube-cluster-production
	$(MAKE) -j2 elasticache-staging elasticache-production
	$(MAKE) kube-pipeline

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
	#aws ssm put-parameter \
#		--name "/$(APPLICATION_NAME)/$(ENVIRONMENT)/kubernetes/cluster-name" \
#		--value "$(APPLICATION_NAME)-$(ENVIRONMENT)" \
#		--type "String" \
#		--overwrite
kube-environment: requires-environment-set kube-s3-bucket
	aws cloudformation package --template-file kubernetes/kube-environment.yml --output-template kubernetes/kube-environment-processed.yml --s3-bucket $(S3_BUCKET_NAME)
	aws cloudformation deploy    \
		--stack-name kube-$(APPLICATION_NAME)-$(ENVIRONMENT)   \
		--template-file kubernetes/kube-environment-processed.yml    \
		--parameter-overrides  \
			ApplicationName=$(APPLICATION_NAME) \
			Environment=$(ENVIRONMENT)

delete-kube-cluster: requires-environment-set
	eksctl delete cluster $(APPLICATION_NAME)-$(ENVIRONMENT)

elasticache-staging:
	$(MAKE) elasticache ENVIRONMENT=staging
elasticache-production:
	$(MAKE) elasticache ENVIRONMENT=production
elasticache: requires-environment-set
	$(eval VPC_ID := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='eksctl-$(APPLICATION_NAME)-$(ENVIRONMENT)-cluster::VPC'].Value" --output text))
	$(eval PRIVATE_SUBNET_IDS := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='eksctl-$(APPLICATION_NAME)-$(ENVIRONMENT)-cluster::SubnetsPrivate'].Value" --output text))
	$(eval APPLICATION_SECURITY_GROUP_ID := $(shell aws cloudformation list-exports --region $(AWS_REGION) --query "Exports[?Name=='eksctl-$(APPLICATION_NAME)-$(ENVIRONMENT)-cluster::SharedNodeSecurityGroup'].Value" --output text))
	aws cloudformation deploy    \
		--stack-name $(ELASTICACHE_STACK_BASE_NAME)-$(ENVIRONMENT)   \
		--template-file environment/elasticache/redis-cluster.yml    \
		--parameter-overrides     \
		ApplicationName=$(APPLICATION_NAME)   \
		Environment=$(ENVIRONMENT) \
		VpcId=$(VPC_ID) \
		SubnetIds=$(PRIVATE_SUBNET_IDS) \
		ApplicationSecurityGroupId=$(APPLICATION_SECURITY_GROUP_ID)
delete-elasticache-staging:
	$(MAKE) delete-elasticache ENVIRONMENT=staging
delete-elasticache-production:
	$(MAKE) delete-elasticache ENVIRONMENT=production
delete-elasticache: requires-environment-set
	./stack-deletion/delete-stack-wait-termination.sh $(ELASTICACHE_STACK_BASE_NAME)-$(ENVIRONMENT)

kube-pipeline: kube-s3-bucket
	aws cloudformation deploy    \
		--stack-name $(KUBE_PIPELINE_STACK_NAME)   \
		--template-file kubernetes/pipeline/kubernetes-pipeline.yml    \
		--capabilities CAPABILITY_NAMED_IAM   \
		--parameter-overrides     \
		ApplicationName=$(APPLICATION_NAME)   \
		S3Bucket=$(KUBE_S3_BUCKET_NAME) \
		GithubRepo=$(GITHUB_REPO)   \
		GithubRepoBranch=$(GITHUB_REPO_BRANCH) \

delete-kube-pipeline:
	./stack-deletion/delete-stack-wait-termination.sh $(KUBE_PIPELINE_STACK_NAME)


delete-kube-all:
	- $(MAKE) delete-kube-pipeline
	- $(MAKE) delete-elasticache ENVIRONMENT=staging
	- $(MAKE) delete-kube-cluster ENVIRONMENT=staging
	- $(MAKE) delete-elasticache ENVIRONMENT=production
	- $(MAKE) delete-kube-cluster ENVIRONMENT=production
	- $(MAKE) delete-kube-s3-bucket
delete-kube-all-light:
	$(MAKE) -j4 delete-kube-pipeline delete-elasticache-staging delete-elasticache-production delete-kube-s3-bucket

kube-s3-bucket:
	aws cloudformation deploy    \
          --stack-name $(KUBE_S3_BUCKET_STACK_NAME)   \
          --template-file s3-bucket/s3-bucket.yml   \
          --parameter-overrides     \
            BucketName=$(KUBE_S3_BUCKET_NAME)
delete-kube-s3-bucket:
	./stack-deletion/delete-stack-wait-termination.sh $(KUBE_S3_BUCKET_STACK_NAME)
