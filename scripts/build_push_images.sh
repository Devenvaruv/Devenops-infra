#!/bin/bash
# scripts/build_push_images.sh

set -e

SERVICES=("frontend" "auth-service" )
DATE_TAG=$1

for SERVICE in "${SERVICES[@]}"
do
  echo "🚀 Building $SERVICE ..."
  docker build -t "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SERVICE:nightly-$DATE_TAG" ./devenops-source/$SERVICE
  echo "📤 Pushing $SERVICE to ECR ..."
  docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SERVICE:nightly-$DATE_TAG"
  echo "✅ Finished $SERVICE"
done