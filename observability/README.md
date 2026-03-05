# Observability Assets

This folder contains Project 6 observability configuration artifacts.

## Files

- `prometheus/prometheus.yml` - scrape config for backend `/metrics` and Node Exporter
- `prometheus/alerts.yml` - Prometheus alert rules (error rate, latency, target down)
- `grafana/dashboards/rps-observability.json` - starter Grafana dashboard (RPS, error rate, p95 latency)

## Notes

- `prometheus.yml` expects these target names on the same network:
  - `backend:5000`
  - `node-exporter:9100`
- Update targets if Prometheus runs on a different host/network.
- Import dashboard JSON into Grafana via:
  - `Dashboards -> New -> Import -> Upload JSON file`

