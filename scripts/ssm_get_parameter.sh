#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/ssm_get_parameter.sh /aw/bootcamp/db/password us-east-1
NAME=${1:?param name}
REGION=${2:-us-east-1}

aws ssm get-parameter \
  --name "$NAME" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text \
  --region "$REGION"
