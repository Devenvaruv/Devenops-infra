#!/bin/bash

set -e
DATE_TAG=$(date +"%Y%m%d")
ACCOUNT_ID=$1
OLD_TAG=$2        
SOURCE_TAG="$OLD_TAG-$DATE_TAG"      
REGION="us-east-1"
REPOSITORIES=("frontend" "auth-service")

for REPO in "${REPOSITORIES[@]}"; do
  echo "📦 Processing $REPO..."

  echo "📄 Fetching existing image tags..."
  ALL_TAGS=$(aws ecr list-images \
    --repository-name "$REPO" \
    --query 'imageDetails[*].imageTags' \
    --output json | jq -r '.[] | .[]' | sort)
  
  echo "📌 All tags in $REPO:"
  echo "$ALL_TAGS"


  echo "🔍 Searching for existing versioned tags (vN)..."
  VERSION_TAGS=$(echo "$ALL_TAGS" | grep -E '^v[0-9]+$' || true)
  HIGHEST_VERSION=$(echo "$VERSION_TAGS" | sed 's/v//' | sort -n | tail -n1)

  if [[ -z "$HIGHEST_VERSION" ]]; then
    NEXT_VERSION=1
  else
    NEXT_VERSION=$((HIGHEST_VERSION + 1))
  fi

  VERSION_TAG="v$NEXT_VERSION"
  echo "🔢 Will promote $SOURCE_TAG → $VERSION_TAG"

  echo "🧾 Fetching manifest for $SOURCE_TAG..."
  MANIFEST=$(aws ecr batch-get-image \
    --repository-name "$REPO" \
    --image-ids imageTag="$SOURCE_TAG" \
    --query 'images[0].imageManifest' \
    --output text)

  if [ -z "$MANIFEST" ] || [ "$MANIFEST" == "None" ]; then
    echo "❌ ERROR: Manifest not found for $REPO:$SOURCE_TAG"
    exit 1
  fi

  echo "🏷️ Tagging $REPO:$SOURCE_TAG as $VERSION_TAG"
  aws ecr put-image \
    --repository-name "$REPO" \
    --image-tag "$VERSION_TAG" \
    --image-manifest "$MANIFEST"

  echo "✅ Promoted $REPO:$SOURCE_TAG → $VERSION_TAG"
done

echo "🎯 All images promoted!"
