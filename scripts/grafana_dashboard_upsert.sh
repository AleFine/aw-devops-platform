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
build_dashboard_json() {
  local uid="$1"; shift
  cat <<EOF
{
  "dashboard": {
    "uid": "${uid}",
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
        "title": "CPU Usage (aw-app pods)",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "sum by (pod) (rate(container_cpu_usage_seconds_total{namespace=\"default\",pod=~\"aw-app-.*\",container!=\"POD\"}[5m]))",
            "legendFormat": "{{pod}}"
          }
        ]
      },
      {
        "id": 3,
        "title": "Memory Working Set (aw-app pods)",
        "type": "graph", 
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "sum by (pod) (container_memory_working_set_bytes{namespace=\"default\",pod=~\"aw-app-.*\",container!=\"POD\"})",
            "legendFormat": "{{pod}}"
          }
        ]
      },
      {
        "id": 4,
        "title": "App Requests Total",
        "type": "graph",
        "datasource": "Prometheus",
        "targets": [
          {
            "expr": "bootcamp_requests_total",
            "legendFormat": "requests"
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
}

dashboard_json=$(build_dashboard_json "${DASH_UID}")

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
  exit 0
fi

# Manejo específico de dashboard provisionado (400 Cannot save provisioned dashboard)
if [ "$http_code" -eq 400 ] && echo "$response_body" | grep -qi 'Cannot save provisioned dashboard'; then
  echo "WARN: Dashboard provisionado; generando UID alterno para clon dinámico."
  ALT_UID="${DASH_UID}-ci"
  echo "INFO: Usando UID alterno ${ALT_UID}"
  dashboard_json=$(build_dashboard_json "${ALT_UID}")
  response=$(curl -s -w "%{http_code}" -X POST "${GRAFANA_URL%/}/api/dashboards/db" \
    -H "Authorization: Bearer ${API_KEY}" \
    -H "Content-Type: application/json" \
    --data-raw "${dashboard_json}")
  http_code="${response: -3}"
  response_body="${response%???}"
  if [ "$http_code" -eq 200 ]; then
     echo "--- Éxito: Dashboard alterno '${ALT_UID}' creado ---"
     exit 0
  else
     echo "ERROR: Reintento con UID alterno falló (HTTP $http_code)"
     echo "Respuesta: ${response_body}"
     exit 1
  fi
fi

echo "--- ERROR: Código HTTP ${http_code} ---"
echo "Respuesta de Grafana: ${response_body}"
exit 1