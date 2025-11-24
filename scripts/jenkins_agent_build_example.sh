#!/usr/bin/env bash

set -euo pipefail

IMAGE=${1:-}
CONTEXT=${2:-app}

if [[ -z "$IMAGE" ]]; then
  echo "Usage: $0 <image> [context-dir]" >&2
  exit 1
fi

/kaniko/executor \
  --context "${CONTEXT}" \
  --dockerfile "${CONTEXT}/Dockerfile" \
  --destination "${IMAGE}" \
  --snapshotMode=redo \
  --verbosity=info

echo "Kaniko build complete: ${IMAGE}" 