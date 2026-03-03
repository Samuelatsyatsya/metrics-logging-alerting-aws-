# Observability Runbook

## What was implemented

- OpenTelemetry tracing for HTTP server, HTTP client, and DB calls (mysql2 via Sequelize)
- OTLP trace export to Jaeger
- RED metrics exposed on `/metrics`
- Structured JSON logs with `trace_id` and `span_id`
- Prometheus alert rules for:
  - error rate > 5% for 10 minutes
  - p95 latency > 300ms for 10 minutes
- Grafana dashboard for rate, errors, latency, CPU/memory, and trace drilldown links

## Start stack

Use your existing deployment path (Jenkins/ECS) or local compose.

If running locally, ensure `BACKEND_IMAGE` and `FRONTEND_IMAGE` are set to valid images first.

## Validate alert -> trace -> log correlation

1. Generate load and 4xx errors:

   ```bash
   ./scripts/validate-observability.sh
   ```

2. Confirm Prometheus alerts:

   - `HighErrorRate`
   - `HighRequestLatencyP95`

3. Open Grafana dashboard:

   - `http://localhost:3000`
   - Dashboard: `RPS Observability - RED + Traces`

4. Open Jaeger and verify traces for `rps-backend`:

   - `http://localhost:16686`

5. In CloudWatch or Loki, filter logs using a `trace_id` from step 4 and confirm matching JSON logs include:

   - `trace_id`
   - `span_id`
   - `request_id`

## Cleanup note

No permanent test routes were added.
Validation uses existing API routes with valid/invalid payloads.
Dashboards and alert configurations remain in place.
