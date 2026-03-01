#    
Observability & Security Solution

## Overview
This project extends an existing **containerized web application** by implementing a complete **observability and security stack** using **Prometheus**, **Grafana**, and multiple **AWS services**.

The goal is to provide end-to-end visibility into application performance, infrastructure health, and AWS account security while validating monitoring, alerting, and threat detection capabilities.

---

## Architecture
**High-level components:**
- Containerized web application exposing metrics at `/metrics`
- Prometheus for metrics scraping and storage
- Grafana for visualization and alerting
- AWS CloudWatch for centralized logging
- AWS CloudTrail for API activity tracking
- AWS GuardDuty for threat detection
- Amazon S3 for secure log storage

--- 

## Tools & Technologies
- **Monitoring:** Prometheus, Node Exporter  
- **Visualization & Alerts:** Grafana  
- **Cloud & Security:**  
  - AWS CloudWatch  
  - AWS CloudTrail  
  - AWS GuardDuty  
- **Infrastructure:** Amazon EC2, Docker, Amazon S3  

---

## Implementation Steps

### 1. Application Metrics
- Used the existing containerized application from the **CI/CD project**
- Verified metrics are exposed at:
---

### 2. Prometheus Setup
- Provisioned Prometheus on a new EC2 instance (or container)
- Configured `prometheus.yml` to scrape:
- Application metrics
- Node Exporter metrics

**Key metrics collected:**
- Request count
- Request latency
- Error rates
- Host CPU and memory usage

---

### 3. Grafana Deployment
- Deployed Grafana and connected it to Prometheus
- Created dashboards to visualize:
- Latency
- Requests per second (RPS)
- Error rates

---

### 4. Alerting Configuration
- Configured alerts using Grafana and/or Prometheus rules
- Alert condition:
- **High error rate (> 5%)**
- Verified alerts trigger correctly under simulated load

---

### 5. CloudWatch Logging
- Enabled **CloudWatch Logs**
- Configured Docker containers to stream logs to CloudWatch
- Verified logs appear in the CloudWatch log groups

---

### 6. AWS Security Services

#### CloudTrail
- Enabled **CloudTrail** for account-wide API activity tracking
- Configured CloudTrail logs to be stored in an encrypted S3 bucket
- Applied lifecycle policies to manage log retention

#### GuardDuty
- Enabled **GuardDuty** for continuous threat detection
- Verified findings for suspicious or anomalous activity

---

### 7. Validation & Cleanup
- Verified:
- Metrics collection
- Dashboards render correctly
- Alerts trigger as expected
- AWS logs and security findings are recorded
- Cleaned up:
- EC2 instances
- Monitoring resources
- Unused AWS services

---

## Repository Structure
```text```
.
├── prometheus.yml
├── grafana/
│   └── dashboard.json
├── screenshots/
│   ├── grafana-dashboard.png
│   ├── alerts-triggered.png
│   ├── cloudwatch-logs.png
│   └── guardduty-findings.png
├── report/
│   └── observability-security-report.pdf
└── README.md

## Deliverables

- Prometheus configuration (prometheus.yml)

- Grafana dashboard JSON

- Screenshots of:

    - Dashboards

    - Alerts

    - CloudWatch logs

    - GuardDuty findings

- 2-page report summarizing monitoring insights and security observations

## Evidence of Completion

- Functional Grafana dashboards

- Alerts triggered for high error rates

- CloudWatch logs successfully ingested

- CloudTrail events recorded in S3

- GuardDuty findings generated and reviewed

## Notes

All AWS resources were properly cleaned up after verification to avoid unnecess ary costs.

## Secret Detection and Protection (Gitleaks)

This repository uses `gitleaks` to detect committed secrets and block unsafe changes.

- CI enforcement: Jenkins runs a `Secret Scan (Gitleaks)` stage before image builds.
- Local protection: a pre-commit hook runs `gitleaks` before each commit.

### Enable local hook

```bash
./scripts/install-git-hooks.sh
```

### Manual scan

```bash
docker run --rm -v "$(pwd):/repo" -w /repo ghcr.io/gitleaks/gitleaks:latest \
  detect --source . --no-git --redact --config /repo/.gitleaks.toml --exit-code 1
```
