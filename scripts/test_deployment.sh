#!/bin/bash

set -e

NAMESPACE=$1
SERVICE=$2

if [ -z "$NAMESPACE" ] || [ -z "$SERVICE" ]; then
  echo "❌ Usage: $0 <namespace> <service-name>"
  exit 1
fi

echo "🔎 Fetching external IP for $SERVICE..."

EXTERNAL_IP=""

# Retry for up to 30 seconds (6 tries, 10s apart)
for i in {1..6}; do
  EXTERNAL_IP=$(kubectl get svc $SERVICE -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  
  if [ -n "$EXTERNAL_IP" ]; then
    echo "🌐 Found External IP: $EXTERNAL_IP"
    break
  fi
  
  echo "⏳ External IP not assigned yet... waiting 5 seconds ($i/6)"
  sleep 10
done

if [ -z "$EXTERNAL_IP" ]; then
  echo "❌ Failed to get External IP after 30 seconds."
  exit 1
fi

echo "🚀 Curling http://$EXTERNAL_IP/ ..."
curl -sSf http://$EXTERNAL_IP/ || exit 1

echo "✅ Service responded OK!"
