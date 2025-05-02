#!/bin/bash

set -e

OLD_TAG=$1 
DATE_TAG=$(date +"%Y%m%d")
SOURCE_TAG="$OLD_TAG-$DATE_TAG"
REPOSITORIES=("frontend" "auth-service")
REGION="us-east-1"
ACCOUNT_ID=$2

echo "🚀 Promoting $SOURCE_TAG images to versioned tags..."

for REPO in "${REPOSITORIES[@]}"; do
  echo "🔍 Checking tags for $REPO..."

  # Get all vN tags
  TAGS=$(aws ecr list-images \
    --repository-name "$REPO" \
    --filter "tagStatus=TAGGED" \
    --query 'imageIds[*].tag' \
    --output text)

  # Extract highest version number
  HIGHEST_VERSION=$(echo "$TAGS" | tr '\t' '\n' | grep -E '^v[0-9]+$' | sed 's/v//' | sort -n | tail -n1)
  NEXT_VERSION=${HIGHEST_VERSION:-0}
  NEXT_VERSION=$((NEXT_VERSION + 1))
  VERSION_TAG="v$NEXT_VERSION"

  echo "📦 Fetching manifest for $REPO:$SOURCE_TAG..."

  MANIFEST=$(aws ecr batch-get-image \
    --repository-name $REPO \
    --image-ids imageTag=$SOURCE_TAG \
    --query 'images[0].imageManifest' \
    --output text)

  if [ -z "$MANIFEST" ] || [ "$MANIFEST" == "None" ]; then
    echo "❌ No manifest found for $REPO:$SOURCE_TAG"
    exit 1
  fi

  echo "🏷️ Tagging $REPO:$SOURCE_TAG as $VERSION_TAG..."

  aws ecr put-image \
    --repository-name "$REPO" \
    --image-tag "$VERSION_TAG" \
    --image-manifest "$MANIFEST"

  echo "✅ Promoted $REPO:$SOURCE_TAG to $VERSION_TAG"
done

echo "🎯 All services promoted successfully!"
