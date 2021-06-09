ifndef APPLICATION_NAME
$(error APPLICATION_NAME is not set)
endif
ifndef ENVIRONMENT
$(error ENVIRONMENT is not set)
endif
ifndef AWS_REGION
$(error AWS_REGION is not set)
endif

kubernetes-environment:
	envsubst < kubernetes/cluster/cluster-template.yml > kubernetes/cluster/$(ENVIRONMENT)-cluster-processed.yml
	eksctl create cluster -f  kubernetes/cluster/$(ENVIRONMENT)-cluster-processed.yml

delete-kubernetes-environment:
	eksctl delete cluster $(APPLICATION_NAME)-$(ENVIRONMENT)