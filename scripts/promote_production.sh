#!/bin/bash

set -e

ACCOUNT_ID=$1   # Passed in from GitHub Actions
REGION="us-east-1"
REPOSITORIES=("frontend" "auth-service")

for REPO in "${REPOSITORIES[@]}"; do
  echo "📦 Processing $REPO..."

  # Step 1: Get all image tags
  ALL_TAGS=$(aws ecr list-images \
    --repository-name "$REPO" \
    --filter tagStatus=TAGGED \
    --query 'imageIds[*].tag' \
    --output text | tr '\t' '\n')

  # Step 2: Extract vN tags
  VERSION_TAGS=$(echo "$ALL_TAGS" | grep -E '^v[0-9]+$')
  HIGHEST_VERSION=$(echo "$VERSION_TAGS" | sed 's/v//' | sort -n | tail -n1)

  NEXT_VERSION=$((HIGHEST_VERSION + 1))
  VERSION_TAG="v$NEXT_VERSION"

  echo "🔍 Existing highest version: v$HIGHEST_VERSION → New tag: $VERSION_TAG"

  # Step 3: Find a tag that is NOT already versioned
  SOURCE_TAG=$(echo "$ALL_TAGS" | grep -vE '^v[0-9]+$' | head -n1)

  if [[ -z "$SOURCE_TAG" ]]; then
    echo "❌ No unversioned image found for $REPO. Skipping."
    continue
  fi

  echo "♻️ Promoting $SOURCE_TAG → $VERSION_TAG"

  MANIFEST=$(aws ecr batch-get-image \
    --repository-name "$REPO" \
    --image-ids imageTag=$SOURCE_TAG \
    --query 'images[0].imageManifest' \
    --output text)

  if [ -z "$MANIFEST" ] || [ "$MANIFEST" == "None" ]; then
    echo "❌ Manifest not found for $SOURCE_TAG — skipping."
    continue
  fi

  aws ecr put-image \
    --repository-name "$REPO" \
    --image-tag "$VERSION_TAG" \
    --image-manifest "$MANIFEST"

  echo "✅ Tagged $REPO:$SOURCE_TAG as $VERSION_TAG"
done

echo "🎉 All services promoted to the next version tag!"
