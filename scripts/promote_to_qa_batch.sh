#!/bin/bash

set -e

DATE_TAG=$(date +"%Y%m%d")

SERVICES=("frontend" "auth-service")

echo "🚀 Promoting nightly images to QA via AWS API for date $DATE_TAG..."

for SERVICE in "${SERVICES[@]}"
do
  NIGHTLY_TAG="nightly-$DATE_TAG"
  QA_TAG="qa-$DATE_TAG"
  
  echo "🔍 Fetching image manifest for $SERVICE:$NIGHTLY_TAG..."

  MANIFEST=$(aws ecr batch-get-image \
    --repository-name $SERVICE \
    --image-ids imageTag=$NIGHTLY_TAG \
    --query 'images[0].imageManifest' \
    --output text)

  if [ -z "$MANIFEST" ]; then
    echo "❌ No manifest found for $SERVICE:$NIGHTLY_TAG"
    exit 1
  fi

  echo "📤 Creating QA tag for $SERVICE:$QA_TAG..."

  aws ecr put-image \
    --repository-name $SERVICE \
    --image-tag $QA_TAG \
    --image-manifest "$MANIFEST"

  echo "✅ Promoted $SERVICE to $QA_TAG!"
done

echo "🎯 All services promoted successfully!"
