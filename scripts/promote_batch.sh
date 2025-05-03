#!/bin/bash

set -e
OLD_TAG=$1
NEW_TAG=$2
DATE_TAG=$(date +"%Y%m%d")

SERVICES=("frontend" "auth-service")

echo "🚀 Promoting nightly images to QA via AWS API for date $DATE_TAG..."

for SERVICE in "${SERVICES[@]}"
do
  DEMOTE_TAG="$OLD_TAG-$DATE_TAG"
  PROMOTE_TAG="$NEW_TAG-$DATE_TAG"
  
  echo "🔍 Fetching image manifest for $SERVICE:$DEMOTE_TAG..."

  MANIFEST=$(aws ecr batch-get-image \
    --repository-name $SERVICE \
    --image-ids imageTag=$DEMOTE_TAG \
    --query 'images[0].imageManifest' \
    --output text)

  if [ -z "$MANIFEST" ]; then
    echo "❌ No manifest found for $SERVICE:$DEMOTE_TAG"
    exit 1
  fi

  echo "📤 Creating QA tag for $SERVICE:$PROMOTE_TAG..."

  aws ecr put-image \
    --repository-name $SERVICE \
    --image-tag $PROMOTE_TAG \
    --image-manifest "$MANIFEST"

  echo "✅ Promoted $SERVICE to $PROMOTE_TAG!"
done

echo "🎯 All services promoted successfully!"
