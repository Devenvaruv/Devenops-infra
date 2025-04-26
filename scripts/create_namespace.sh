#!/bin/bash
# scripts/create_namespace.sh

set -e

# Required environment variables
NAMESPACE=$1

if [ -z "$NAMESPACE" ]; then
  echo "❌ Namespace not provided. Usage: ./create_namespace.sh <namespace>"
  exit 1
fi

echo "📦 Creating namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" || echo "⚠️ Namespace $NAMESPACE already exists. Continuing..."
