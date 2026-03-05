# Project 6: Full Observability and Security Solution (AWS)

This repository extends a containerized Rock-Paper-Scissors web application with:

- Application metrics exposure at `/metrics`
- CI/CD deployment pipeline with Jenkins + ECR + EC2
- AWS security telemetry infrastructure with Terraform (CloudTrail + GuardDuty + S3 + CloudWatch log group)

It is designed to satisfy the Project 6 objective: end-to-end observability and security verification using Prometheus, Grafana, CloudWatch, CloudTrail, and GuardDuty.

## 1. Project Scope

Target outcomes for this project:

- Scrape app metrics with Prometheus
- Visualize latency, requests/sec, and error rates in Grafana
- Alert when error rate is above 5%
- Stream container logs to CloudWatch Logs
- Enable CloudTrail and GuardDuty for account/activity security monitoring
- Store CloudTrail logs in encrypted S3 with lifecycle policies
- Verify all monitoring and detections
- Clean up AWS monitoring resources after validation

## 2. Current Repository Contents

Relevant files already present:

- `backend/src/app.js` (includes `/metrics` and `/health`)
- `backend/src/utils/metrics.js` (Prometheus custom + default metrics)
- `backend/src/middleware/metricsMiddleware.js` (request metrics collection)
- `docker-compose.yml` (app + db deployment)
- `Jenkinsfile` (build/push/deploy/health-check pipeline)
- `terraform/main.tf` (security stack composition)
- `terraform/modules/cloudtrail/*` (CloudTrail + encrypted S3 + lifecycle + CloudWatch log group)
- `terraform/modules/guardduty/*` (GuardDuty detector)

## 3. Architecture Summary

1. Frontend (Vite/React) calls backend API.
2. Backend (Express) writes to MySQL and exposes `/metrics`.
3. Prometheus scrapes backend metrics and node metrics (Node Exporter).
4. Grafana reads Prometheus and displays dashboards + alert rules.
5. CloudTrail captures AWS API activity.
6. CloudTrail writes to encrypted S3 and CloudWatch Logs.
7. GuardDuty analyzes CloudTrail/S3 signals for threat findings.

## 4. Prerequisites

- Docker + Docker Compose
- Node.js 18+ (for local non-container runs)
- AWS CLI v2 configured
- Terraform >= 1.7
- Jenkins server with required credentials configured

## 5. Run the Application (Containerized)

`docker-compose.yml` uses prebuilt images, so set image names first.

1. Set environment variables (or update `.env`):
   - `BACKEND_IMAGE`
   - `FRONTEND_IMAGE`
   - `MYSQL_*`, `DB_*`, `BACKEND_PORT`, `FRONTEND_PORT`
   - `API_PREFIX=/api/v1` (important for route mounting)
2. Start stack:

```bash
docker compose up -d
```

3. Validate:

```bash
curl http://localhost:5000/health
curl http://localhost:5000/metrics
curl http://localhost:5173
```

## 6. Metrics Exposed by Backend

From `backend/src/utils/metrics.js`:

- `http_request_duration_seconds` (histogram)
- `http_requests_total` (counter)
- `game_rounds_total` (counter)
- `game_choices_total` (counter)
- `active_games` (gauge)
- `game_session_duration_seconds` (histogram)
- `total_players` (gauge)
- `new_players_total` (counter)
- `database_query_duration_seconds` (histogram)
- Prometheus default process/runtime metrics

## 7. CI/CD Pipeline (Jenkinsfile)

Main stages:

1. Checkout + image tag generation (`BUILD_NUMBER` + commit SHA)
2. Docker availability checks in Jenkins agent
3. Build and push backend/frontend images to ECR
4. SSH setup on EC2 (Docker, Compose, AWS CLI)
5. Deploy stack to EC2 with generated `.env`
6. Health checks for frontend, backend, and `/metrics`

## 8. AWS Security Stack (Terraform)

Terraform in `terraform/` provisions:

- CloudTrail (multi-region, log file validation enabled)
- CloudTrail S3 bucket with:
  - versioning
  - AES256 server-side encryption
  - public access blocked
  - lifecycle transition to Glacier + expiration
- CloudWatch log group for CloudTrail
- IAM role/policy for CloudTrail -> CloudWatch delivery
- GuardDuty detector with S3 log monitoring enabled

Apply:

```bash
cd terraform
terraform init
terraform plan \
  -var="aws_region=<region>" \
  -var="aws_account_id=<account_id>" \
  -var="project_name=project6-observability"
terraform apply \
  -var="aws_region=<region>" \
  -var="aws_account_id=<account_id>" \
  -var="project_name=project6-observability"
```

## 9. Prometheus and Grafana Setup (Project Requirement)

Starter configs are now included in this repo:

- `observability/prometheus/prometheus.yml`
- `observability/prometheus/alerts.yml`
- `observability/grafana/dashboards/rps-observability.json`

Deploy Prometheus and Grafana on a dedicated EC2/container and configure:

- Prometheus scrape jobs:
  - app metrics: `http://<app-host>:5000/metrics`
  - node exporter: `http://<node-exporter-host>:9100/metrics`
- Grafana datasource: Prometheus
- Dashboards:
  - request latency
  - requests per second
  - error rate
- Alerts:
  - trigger when error rate > 5%

Example PromQL for error rate:

```promql
(
  sum(rate(http_requests_total{status_code=~"5.."}[5m]))
/
  sum(rate(http_requests_total[5m]))
) * 100 > 5
```

## 10. CloudWatch Container Logs (Project Requirement)

Configure Docker logging driver for app containers to `awslogs`, then verify logs in CloudWatch Log Groups.

Minimum fields per service in `docker-compose.yml`:

- `logging.driver: awslogs`
- `logging.options.awslogs-region`
- `logging.options.awslogs-group`
- `logging.options.awslogs-stream`

## 11. Verification Checklist

- [ ] `/metrics` returns Prometheus format metrics
- [ ] Prometheus targets are `UP` for app + node exporter
- [ ] Grafana dashboards populated for latency/RPS/errors
- [ ] Error-rate alert (>5%) fires and is visible
- [ ] CloudWatch contains container logs
- [ ] CloudTrail events are recorded in CloudWatch + S3
- [ ] GuardDuty findings appear when test activity is generated

## 12. Deliverables for Submission

Include in this repo:

- `observability/prometheus/prometheus.yml`
- `observability/prometheus/alerts.yml`
- `observability/grafana/dashboards/rps-observability.json`
- screenshots:
  - dashboards
  - alert firing/resolved
  - CloudWatch logs
  - CloudTrail events
  - GuardDuty findings
- 2-page report summarizing:
  - architecture
  - metrics/alerts behavior
  - security findings
  - key insights and remediation actions

## 13. Cleanup

After verification, remove monitoring resources to control cost:

```bash
cd terraform
terraform destroy \
  -var="aws_region=<region>" \
  -var="aws_account_id=<account_id>" \
  -var="project_name=project6-observability"
```

Also terminate temporary EC2 instances used for Prometheus/Grafana if created outside Terraform.
