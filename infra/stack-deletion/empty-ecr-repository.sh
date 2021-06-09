#!/bin/bash

if [ -z $1 ]; then
  echo -e "usage:\n./empty-ecr-repository.sh \$ECR_REPOSITORY_NAME"
  exit 1
fi

aws ecr list-images \
  --repository-name $1 | \
  jq -r ' .imageIds[] | [ .imageDigest ] | @tsv ' | \
  while IFS=$'\t' read -r imageDigest; do
    aws ecr batch-delete-image \
      --repository-name $1 \
      --image-ids imageDigest=$imageDigest
  done