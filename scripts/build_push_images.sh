#!/bin/bash
# scripts/build_push_images.sh
set -e

SERVICES=("frontend" "auth")
# DATE_TAG=20250504
DATE_TAG=$(date +"%Y%m%d")

# Gets list of changed directories in devenops-source/
CHANGED_SERVICES=$(git -C devenops-source diff --name-only HEAD~1 HEAD | awk -F/ '{print $1}' | sort -u)

for SERVICE in "${SERVICES[@]}"; do
  if echo "$CHANGED_SERVICES" | grep -q "^$SERVICE$"; then
    echo "🚀 Changes detected in $SERVICE, building image..."
    docker build -t "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SERVICE:nightly-$DATE_TAG" ./devenops-source/$SERVICE
    docker push "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$SERVICE:nightly-$DATE_TAG"
    echo "✅ $SERVICE pushed"
  else
    echo "⏭️ No changes in $SERVICE, skipping build"
  fi
done