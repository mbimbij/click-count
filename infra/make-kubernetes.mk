ifndef APPLICATION_NAME
$(error APPLICATION_NAME is not set)
endif

include make-bucket.mk

KUBE_PIPELINE_STACK_NAME=$(APPLICATION_NAME)-kube-pipeline

kubernetes-environment:
	@if [ -z $(ENVIRONMENT) ]; then exit 255; fi
	envsubst < kubernetes/cluster/cluster-template.yml > kubernetes/cluster/$(ENVIRONMENT)-cluster-processed.yml
	eksctl create cluster -f  kubernetes/cluster/$(ENVIRONMENT)-cluster-processed.yml

delete-kubernetes-environment:
	eksctl delete cluster $(APPLICATION_NAME)-$(ENVIRONMENT)


kubernetes-pipeline: s3-bucket
	aws cloudformation deploy    \
		--stack-name $(KUBE_PIPELINE_STACK_NAME)   \
		--template-file kubernetes/pipeline/kubernetes-pipeline.yml    \
		--capabilities CAPABILITY_NAMED_IAM   \
		--parameter-overrides     \
		ApplicationName=$(APPLICATION_NAME)   \
		S3Bucket=$(S3_BUCKET_NAME) \
		GithubRepo=$(GITHUB_REPO)   \
		GithubRepoBranch=$(GITHUB_REPO_BRANCH) \

delete-kubernetes-pipeline:
	./stack-deletion/delete-stack-wait-termination.sh $(KUBE_PIPELINE_STACK_NAME)