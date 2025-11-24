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

# CORREGIDO: JSON válido para Grafana
dashboard_json=$(cat <<EOF
{
  "dashboard": {
    "uid": "${DASH_UID}",
    "title": "Bootcamp App Metrics",
    "tags": ["bootcamp", "deployment"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Deployment Info",
        "type": "text",
        "mode": "markdown",
        "content": "# Current Deployment\n**Image:** \`${IMAGE_TAG}\`\n**Time:** $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
      },
      {
        "id": 2,
        "title": "CPU Usage",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "sum(rate(container_cpu_usage_seconds_total{container=~\"aw-app.*\"}[5m]))",
            "legendFormat": "CPU Usage"
          }
        ]
      },
      {
        "id": 3,
        "title": "Memory Usage",
        "type": "graph", 
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "sum(container_memory_working_set_bytes{container=~\"aw-app.*\"})",
            "legendFormat": "Memory Bytes"
          }
        ]
      }
    ],
    "templating": {
      "list": []
    },
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  },
  "message": "Updated by Jenkins pipeline - ${IMAGE_TAG}",
  "overwrite": true
}
EOF
)

echo "--- Iniciando Carga de Dashboard a Grafana ---"
echo "URL: ${GRAFANA_URL}"
echo "Dashboard UID: ${DASH_UID}"

# PRIMERO: Verificar que Grafana responde
echo "--- Verificando conexión con Grafana ---"
if ! curl -s -H "Authorization: Bearer ${API_KEY}" "${GRAFANA_URL%/}/api/health" > /dev/null; then
    echo "ERROR: No se puede conectar a Grafana o API key inválida"
    exit 1
fi

# SEGUNDO: Enviar dashboard
response=$(curl -s -w "%{http_code}" -X POST "${GRAFANA_URL%/}/api/dashboards/db" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  --data-raw "${dashboard_json}")

http_code="${response: -3}"
response_body="${response%???}"

if [ "$http_code" -eq 200 ]; then
    echo "--- Éxito: Dashboard '${DASH_UID}' actualizado ---"
    echo "Image: ${IMAGE_TAG}"
else
    echo "--- ERROR: Código HTTP ${http_code} ---"
    echo "Respuesta de Grafana: ${response_body}"
    exit 1
fi