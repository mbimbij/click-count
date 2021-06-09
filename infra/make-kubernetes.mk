ifndef APPLICATION_NAME
$(error APPLICATION_NAME is not set)
endif

kubernetes-environment:
	@if [ -z $(ENVIRONMENT) ]; then exit 255; fi
	envsubst < kubernetes/cluster/cluster-template.yml > kubernetes/cluster/$(ENVIRONMENT)-cluster-processed.yml
	eksctl create cluster -f  kubernetes/cluster/$(ENVIRONMENT)-cluster-processed.yml

delete-kubernetes-environment:
	eksctl delete cluster $(APPLICATION_NAME)-$(ENVIRONMENT)

kubernetes-pipeline: s3-bucket
