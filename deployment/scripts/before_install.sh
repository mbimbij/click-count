#! /bin/bash

# making the application working directory and configuration at the same time
mkdir -p /opt/application/conf

# deleting old files just in case
rm -rf /etc/systemd/system/application.service
rm -rf /opt/application/application.jar
rm -rf /opt/application/application-server.yml

## configuring AWS_REGION for the CLI, because it somehow triggers errors with CodeDeploy
#AWS_REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq .region -r)
#aws configure set region $AWS_REGION
#
## fetching ec2 instance environment
#INSTANCE_ID=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.instanceId')
#ENVIRONMENT=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" --query "Tags[?Key=='Environment'].Value" --output text)
#
## fetching redis configuration for the environment and passing it to spring-boot app as environment variables
#REDIS_HOST=$(aws ssm get-parameter --name /my-app/$ENVIRONMENT/redis/address --query "Parameter.Value" --output text)
#REDIS_PORT=$(aws ssm get-parameter --name /my-app/$ENVIRONMENT/redis/port --query "Parameter.Value" --output text)
#export REDIS_HOST
#export REDIS_PORT
#
## echoing the variables just to be sure
#echo "AWS_REGION: AWS_REGION"
#echo "INSTANCE_ID: INSTANCE_ID"
#echo "ENVIRONMENT: ENVIRONMENT"
#echo "REDIS_HOST: $REDIS_HOST"
#echo "REDIS_PORT: $REDIS_PORT"
#
## echoing the environment variables just to be sure
#env
#ls
#pwd
#
## setting a spring configuration file for the environment
#envsubst < /tmp/application-template.yml  > /opt/application/conf/application-server.yml