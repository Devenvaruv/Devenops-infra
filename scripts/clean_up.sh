#!/bin/bash
# scripts/cleanup.sh
set -e

NAMESPACE=$1

kubectl delete namespace $NAMESPACE
