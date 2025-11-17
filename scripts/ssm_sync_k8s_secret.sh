#!/usr/bin/env bash
set -euo pipefail

# Syncs SSM parameters into a Kubernetes secret for aw-app
# Usage: ./scripts/ssm_sync_k8s_secret.sh aw aw-app-secrets /aw/bootcamp/db/username /aw/bootcamp/db/password us-east-1
NS=${1:-aw}
SECRET=${2:-aw-app-secrets}
PARAM_USER=${3:-/aw/bootcamp/db/username}
PARAM_PASS=${4:-/aw/bootcamp/db/password}
REGION=${5:-us-east-1}

USER_VAL=$(aws ssm get-parameter --name "$PARAM_USER" --with-decryption --query 'Parameter.Value' --output text --region "$REGION")
PASS_VAL=$(aws ssm get-parameter --name "$PARAM_PASS" --with-decryption --query 'Parameter.Value' --output text --region "$REGION")

echo "Syncing secret $SECRET in namespace $NS"

kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f -

kubectl -n "$NS" delete secret "$SECRET" --ignore-not-found
kubectl -n "$NS" create secret generic "$SECRET" \
  --from-literal=db_username="$USER_VAL" \
  --from-literal=db_password="$PASS_VAL"

echo "Secret synced"
