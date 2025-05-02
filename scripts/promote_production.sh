#!/bin/bash

set -e

ACCOUNT_ID=$1
REGION="us-east-1"
REPOSITORIES=("frontend" "auth-service")

for REPO in "${REPOSITORIES[@]}"; do
  echo "📦 Processing $REPO..."

  echo "🧾 Listing all image tags..."
  ALL_TAGS=$(aws ecr list-images \
    --repository-name "$REPO" \
    --filter tagStatus=TAGGED \
    --query 'imageIds[*].tag' \
    --output text | tr '\t' '\n')

  echo "Tags found: $ALL_TAGS"

  VERSION_TAGS=$(echo "$ALL_TAGS" | grep -E '^v[0-9]+$' || true)
  HIGHEST_VERSION=$(echo "$VERSION_TAGS" | sed 's/v//' | sort -n | tail -n1)
  NEXT_VERSION=$((HIGHEST_VERSION + 1))
  VERSION_TAG="v$NEXT_VERSION"

  echo "🔍 Highest version: v$HIGHEST_VERSION → Next: $VERSION_TAG"

  SOURCE_TAG=$(echo "$ALL_TAGS" | grep -vE '^v[0-9]+$' | head -n1)

  if [[ -z "$SOURCE_TAG" ]]; then
    echo "❌ No unversioned image found. Skipping $REPO."
    continue
  fi

  echo "📤 Promoting $SOURCE_TAG → $VERSION_TAG..."

  MANIFEST=$(aws ecr batch-get-image \
    --repository-name "$REPO" \
    --image-ids imageTag=$SOURCE_TAG \
    --query 'images[0].imageManifest' \
    --output text)

  if [ -z "$MANIFEST" ] || [ "$MANIFEST" == "None" ]; then
    echo "❌ Manifest not found for $SOURCE_TAG — skipping."
    continue
  fi

  echo "📝 Putting image: $VERSION_TAG"
  aws ecr put-image \
    --repository-name "$REPO" \
    --image-tag "$VERSION_TAG" \
    --image-manifest "$MANIFEST"

  echo "✅ Done: $SOURCE_TAG → $VERSION_TAG"
done
