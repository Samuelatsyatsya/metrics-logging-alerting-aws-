#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:5000}"
API_PREFIX="${API_PREFIX:-/api/v1}"
SUCCESS_REQUESTS="${SUCCESS_REQUESTS:-200}"
ERROR_REQUESTS="${ERROR_REQUESTS:-25}"
PARALLELISM="${PARALLELISM:-20}"
JAEGER_SERVICE="${JAEGER_SERVICE:-rps-backend}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"
JAEGER_API_URL="${JAEGER_API_URL:-http://localhost:16686}"

VALID_PAYLOAD='{"username":"obs-load","result":"win","player_choice":"rock","computer_choice":"scissors","session_duration":1}'
INVALID_PAYLOAD='{"username":"","result":"invalid","player_choice":"x","computer_choice":"y","session_duration":-1}'

echo "[1/6] Sending successful traffic (${SUCCESS_REQUESTS} requests)..."
seq "${SUCCESS_REQUESTS}" | xargs -I{} -P "${PARALLELISM}" bash -c '
  curl -sS -o /dev/null \
    -X POST "${0}${1}/game/submit" \
    -H "Content-Type: application/json" \
    -d "${2}"
' "${BASE_URL}" "${API_PREFIX}" "${VALID_PAYLOAD}"

echo "[2/6] Sending invalid traffic to generate 4xx errors (${ERROR_REQUESTS} requests)..."
seq "${ERROR_REQUESTS}" | xargs -I{} -P "${PARALLELISM}" bash -c '
  curl -sS -o /dev/null \
    -X POST "${0}${1}/game/submit" \
    -H "Content-Type: application/json" \
    -d "${2}" || true
' "${BASE_URL}" "${API_PREFIX}" "${INVALID_PAYLOAD}"

echo "[3/6] Metrics snapshot (RED + resource metrics):"
curl -sS "${BASE_URL}/metrics" | grep -E 'http_server_requests_total|http_server_errors_total|http_server_request_duration_seconds_bucket|process_cpu_user_seconds_total|process_resident_memory_bytes' || true

echo "[4/6] Prometheus active alerts (if threshold already crossed for full 10m):"
curl -sS -G "${PROMETHEUS_URL}/api/v1/query" \
  --data-urlencode 'query=ALERTS{alertname=~"HighErrorRate|HighRequestLatencyP95"}' || true

echo "[5/6] Recent Jaeger traces for service ${JAEGER_SERVICE}:"
curl -sS -G "${JAEGER_API_URL}/api/traces" \
  --data-urlencode "service=${JAEGER_SERVICE}" \
  --data-urlencode "limit=3" || true

echo "[6/6] Correlation checks:"
echo "- Open Grafana: your existing Grafana URL"
echo "- Open Jaeger:  ${JAEGER_API_URL}"
echo "- In CloudWatch/Loki logs, filter JSON logs by trace_id or span_id"
echo "- Confirm alert -> trace -> log path using the same trace_id"
