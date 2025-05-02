#!/bin/bash

set -e
DATE_TAG=$(date +"%Y%m%d")
ACCOUNT_ID=$1         
SOURCE_TAG=$2-$DATE_TAG        
REGION="us-east-1"
REPOSITORIES=("frontend" "auth-service")

for REPO in "${REPOSITORIES[@]}"; do
  echo "📦 Processing $REPO..."

  # Step 1: List all tags
  ALL_TAGS=$(aws ecr list-images \
    --repository-name "$REPO" \
    --filter tagStatus=TAGGED \
    --query 'imageIds[*].tag' \
    --output text | tr '\t' '\n')

  if [[ -z "$ALL_TAGS" ]]; then
    echo "⚠️ No images found for $REPO. Skipping."
    continue
  fi

  # Step 2: Find highest vN
  VERSION_TAGS=$(echo "$ALL_TAGS" | grep -E '^v[0-9]+$' || true)
  HIGHEST_VERSION=$(echo "$VERSION_TAGS" | sed 's/v//' | sort -n | tail -n1)
  NEXT_VERSION=$((HIGHEST_VERSION + 1))
  VERSION_TAG="v$NEXT_VERSION"

  echo "🔢 Promoting tag: $SOURCE_TAG → $VERSION_TAG"

  # Step 3: Get manifest of source tag
  MANIFEST=$(aws ecr batch-get-image \
    --repository-name "$REPO" \
    --image-ids imageTag="$SOURCE_TAG" \
    --query 'images[0].imageManifest' \
    --output text)

  if [ -z "$MANIFEST" ] || [ "$MANIFEST" == "None" ]; then
    echo "❌ Manifest not found for $REPO:$SOURCE_TAG. Skipping."
    continue
  fi

  # Step 4: Create versioned tag
  aws ecr put-image \
    --repository-name "$REPO" \
    --image-tag "$VERSION_TAG" \
    --image-manifest "$MANIFEST"

  echo "✅ $REPO:$SOURCE_TAG promoted to $VERSION_TAG"
done

echo "🎉 Promotion complete!"
