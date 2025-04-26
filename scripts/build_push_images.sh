#!/bin/bash
# scripts/build_push_images.sh

set -e

SERVICES=("service1" "service2" "service3")
DATE_TAG=$(date +"%Y%m%d")

for SERVICE in "${SERVICES[@]}"
do
  docker build -t "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SERVICE:nightly-$DATE_TAG" ./source-repo/$SERVICE
  docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SERVICE:nightly-$DATE_TAG"
done
