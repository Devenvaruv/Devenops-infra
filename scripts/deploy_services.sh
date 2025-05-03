#!/bin/bash
# scripts/deploy_services.sh

set -e

NAMESPACE=$1
CUSTOM_TAG=$2

if [ -z "$NAMESPACE" ]; then
  echo "❌ Namespace not provided. Usage: ./deploy_services.sh <namespace>"
  exit 1
fi

# Function to get the latest vN tag from a given repo
get_latest_tag() {
  local repo=$1
  aws ecr describe-images \
    --repository-name "$repo" \
    --query 'imageDetails[*].imageTags' \
    --output json |
    jq -r '.[]? | .[]?' |
    grep -E '^v[0-9]+$' |
    sed 's/v//' |
    sort -n |
    tail -n1
}

# Apply deployments and services with correct tag per service
for yaml in ./k8s/deployments/*.yaml ./k8s/services/*.yaml
do
  # Guess the repo name from the file name (e.g., auth-service-deployment.yaml → auth-service)
  if [[ $yaml == *frontend* ]]; then
    REPO="frontend"
  elif [[ $yaml == *auth-service* ]]; then
    REPO="auth-service"
  else
    echo "⚠️ Skipping unknown file: $yaml"
    continue
  fi

  
  if [[ -n "$CUSTOM_TAG" ]]; then
    export TAG="$CUSTOM_TAG"
  else
    echo "🔍 Getting latest version tag for $REPO..."
    LATEST_NUM=$(get_latest_tag "$REPO")

    if [ -z "$LATEST_NUM" ]; then
      echo "❌ No version tags found for $REPO. Skipping $yaml"
      continue
    fi
    TAG="v$LATEST_NUM"
  fi
  echo "📦 Using tag $TAG for $REPO ($yaml)"

  export TAG  # For envsubst
  envsubst < "$yaml" | kubectl apply -n "$NAMESPACE" -f -

done

echo "✅ All deployments applied with correct version tags!"
