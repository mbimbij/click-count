include infra.env

ifndef APPLICATION_NAME
$(error APPLICATION_NAME is not set)
endif
ifndef AWS_REGION
$(error AWS_REGION is not set)
endif

include make-bucket.mk
include make-ec2.mk
include make-kubernetes.mk

SHELL := /bin/bash

AWS_ACCOUNT_ID := $(shell aws sts get-caller-identity --query "Account" --output text)

GITHUB_REPO_BRANCH=$(shell git rev-parse --abbrev-ref HEAD)

requires-environment-set:
	@if [ -z $(ENVIRONMENT) ]; then >&2 echo "ENVIRONMENT is not set"; exit 255; fi
