#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/ssm_put_parameter.sh /aw/bootcamp/db/password supersecret us-east-1
NAME=${1:?param name}
VALUE=${2:?param value}
REGION=${3:-us-east-1}

echo "Putting SecureString parameter $NAME in $REGION"
aws ssm put-parameter \
  --name "$NAME" \
  --value "$VALUE" \
  --type SecureString \
  --overwrite \
  --region "$REGION"

echo "Done"
