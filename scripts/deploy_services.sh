#!/bin/bash
# scripts/deploy_services.sh

set -e

NAMESPACE=$1

if [ -z "$NAMESPACE" ]; then
  echo "❌ Namespace not provided. Usage: ./deploy_services.sh <namespace>"
  exit 1
fi

# DATE_TAG=$(date +"%Y%m%d")
DATE_TAG=20250503
export TAG="$NAMESPACE-$DATE_TAG"

# Apply deployments with correct nightly tags
for yaml in ./k8s/deployments/*.yaml ./k8s/services/*.yaml
do
  echo "🚀 Applying $yaml into namespace $NAMESPACE with tag $TAG ..."
  envsubst < "$yaml" | kubectl apply -n "$NAMESPACE" -f -
done

echo "✅ Deployment complete!"