#!/bin/bash

set -e

DOMAIN_NAME=$1
NAMESPACE=$2
SERVICE_NAME=$3

if [[ -z "$DOMAIN_NAME" || -z "$NAMESPACE" || -z "$SERVICE_NAME" ]]; then
  echo "❌ Usage: ./update_dns.sh <domain_name> <namespace> <service_name>"
  exit 1
fi

echo " Fetching LoadBalancer for $SERVICE_NAME in $NAMESPACE..."

LB_HOSTNAME=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$LB_HOSTNAME" ]; then
  echo "❌ Could not find LoadBalancer hostname. Exiting."
  exit 1
fi

echo "Found LB Hostname: $LB_HOSTNAME"
echo "Creating Route53 CNAME record for $DOMAIN_NAME..."

cat <<EOF > change-batch.json
{
  "Comment": "Map $DOMAIN_NAME to $LB_HOSTNAME",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$DOMAIN_NAME.",
      "Type": "CNAME",
      "TTL": 60,
      "ResourceRecords": [{
        "Value": "$LB_HOSTNAME"
      }]
    }
  }]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch file://change-batch.json

echo "✅ CNAME record updated successfully!"
