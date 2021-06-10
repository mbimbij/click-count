#!/bin/bash

if [ -z $1 ]; then
  echo -e "usage:\n./delete-parameteres-from-store.sh \$APPLICATION_NAME"
  exit 1
fi

APPLICATION_NAME=$1

echo -e "##############################################################################"
echo -e "deleting parameters from application $APPLICATION_NAME"
echo -e "##############################################################################"
PARAMETERS=$(aws ssm get-parameters-by-path --path "/$APPLICATION_NAME" --recursive --query "Parameters[].Name" --output text)
for PARAMETER in $PARAMETERS; do
  echo "deleting parameter $PARAMETER"
  aws ssm delete-parameter --name $PARAMETER
done