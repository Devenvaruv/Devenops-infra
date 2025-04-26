#!/bin/bash

NAMESPACE=$1
SERVICE=$2

echo "🔎 Fetching external IP for $SERVICE..."

EXTERNAL_IP=$(kubectl get svc $SERVICE -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "🌐 External IP: $EXTERNAL_IP"

echo "🚀 Curling http://$EXTERNAL_IP/ ..."
curl -sSf http://$EXTERNAL_IP/ || exit 1

echo "✅ Service responded OK!"
