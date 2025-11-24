#!/usr/bin/env bash
set -euo pipefail

GRAFANA_URL=${1:-}
API_KEY=${2:-}
DASH_UID=${3:-bootcamp-app}
IMAGE_TAG=${4:-unknown}

if [[ -z "$GRAFANA_URL" || -z "$API_KEY" ]]; then
  echo "Usage: $0 <grafana_url> <api_key> [dashboard_uid] [image]" >&2
  exit 1
fi

dashboard_json=$(cat <<EOF
{
  "dashboard": {
    "uid": "${DASH_UID}",
    "title": "Bootcamp App Deployment",
    "tags": ["bootcamp","deployment"],
    "timezone": "browser",
    "panels": [
      {"type":"stat","title":"Image","datasource":null,"id":1,
       "options":{"reduceOptions":{"calcs":["lastNotNull"],"fields":"","values":false},"textMode":"name"},
       "targets":[],"fieldConfig":{"defaults":{"custom":{}},"overrides":[]},
       "pluginVersion":"10.x"},
      {"type":"graph","title":"CPU","datasource":"Prometheus","id":2,
       "targets":[{"expr":"sum(rate(container_cpu_usage_seconds_total{pod=~\"aw-app.*\",container!='POD'}[5m]))"}]},
      {"type":"graph","title":"Memory","datasource":"Prometheus","id":3,
       "targets":[{"expr":"sum(container_memory_working_set_bytes{pod=~\"aw-app.*\",container!='POD'})"}]}
    ],
    "templating": {"list": []},
    "annotations": {"list": []},
    "schemaVersion": 38,
    "version": 1
  },
  "message": "Updated after deploy of ${IMAGE_TAG}",
  "overwrite": true
}
EOF
)

echo "--- Iniciando Carga de Dashboard a Grafana ---"
curl -v --fail -X POST "${GRAFANA_URL%/}/api/dashboards/db" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H 'Content-Type: application/json' \
  --data-raw "${dashboard_json}" || {
    echo "--- El comando curl de Grafana falló con el error de arriba. ---" >&2; exit 1; }

echo "--- Éxito: Grafana dashboard '${DASH_UID}' actualizado (image: ${IMAGE_TAG}). ---"