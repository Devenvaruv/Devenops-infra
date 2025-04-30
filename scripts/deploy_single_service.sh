#!/usr/bin/env bash
# Usage: deploy_single_service.sh <slot> <base_name> <tag>
set -euo pipefail
SLOT="$1"          # blue | green
NAME="$2"          # auth-service  (base name for Deployment / Service)
TAG="$3"           # prod-YYYYMMDDhhmmss
NS=${K8S_NAMESPACE:-blue}

# render manifest on the fly (uses envsubst-compatible vars)
export SLOT TAG NAME
cat <<'YAML' | envsubst | kubectl apply -n "$NS" -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${NAME}-${SLOT}
  labels: { app: ${NAME}, slot: ${SLOT} }
spec:
  replicas: 1
  selector: { matchLabels: { app: ${NAME}, slot: ${SLOT} } }
  template:
    metadata:
      labels: { app: ${NAME}, slot: ${SLOT} }
    spec:
      containers:
        - name: ${NAME}
          image: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${NAME}:${TAG}
          ports:
            - containerPort: 5000
YAML
