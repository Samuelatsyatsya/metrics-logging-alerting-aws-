# Metrics, Logging, Alerting AWS Project

## Overview
This repository is a full-stack Rock-Paper-Scissors application with:
- React frontend (`frontend/`)
- Express + Sequelize backend (`backend/`)
- MySQL persistence
- Terraform infrastructure for AWS (ECS Fargate, ALB, RDS, CloudWatch, IAM, optional CodeDeploy)
- Jenkins CI/CD pipeline with integrated security and quality gates

It is designed as a three-tier deployment demo with observability and DevSecOps controls built into delivery.

## Current Architecture
- Frontend: Vite + React + Tailwind UI
- Backend: Express API with Joi validation, rate limiting, Helmet, CORS
- Database: MySQL (local container or AWS RDS)
- Runtime metrics: Prometheus-format `/metrics` endpoint from backend
- Cloud logs and alarms: ECS task logs in CloudWatch; pipeline verification for log streams and alarm presence
- Deployment target: AWS ECS Fargate behind an ALB

## Repository Layout
```text
.
├── backend/                 # Express API + Sequelize models + tests
├── frontend/                # React app + tests
├── terraform/               # Root IaC modules + tfvars
│   ├── modules/
│   │   ├── network/
│   │   ├── ecs/
│   │   ├── rds/
│   │   ├── jenkins_iam/
│   │   └── codedeploy/
│   └── terraform-bootstrap/ # Optional state bucket bootstrap
├── Jenkinsfile              # CI/CD + security scans + ECS deployment
├── docker-compose.yml       # Local multi-container stack
└── scripts/install-git-hooks.sh
```

## Backend API
Base prefix defaults to `/api/v1`.

- `GET /health` - service health
- `GET /metrics` - Prometheus metrics
- `GET /api/v1/health` - API health
- `POST /api/v1/game/submit` - submit game round
- `GET /api/v1/game/leaderboard?limit=10` - leaderboard
- `GET /api/v1/game/player/:username` - player stats
- `GET /api/v1/game/player/:username/history?page=1&limit=10` - paginated history

## Metrics Exposed by Backend
- `http_request_duration_seconds`
- `http_requests_total`
- `game_rounds_total`
- `game_choices_total`
- `active_games`
- `game_session_duration_seconds`
- `total_players`
- `new_players_total`
- `database_query_duration_seconds`
- default Node.js process/runtime metrics via `prom-client`

## Local Development

### Prerequisites
- Node.js 18+ (20 recommended)
- npm
- Docker + Docker Compose

### Environment configuration
- Backend uses `backend/.env` (`DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_PORT`, `DB_DIALECT`, `PORT`, `NODE_ENV`, `API_PREFIX`, `CORS_ORIGIN`, `HOST`).
- Frontend uses `frontend/.env` (`VITE_API_URL`, optional `VITE_APP_NAME`, `VITE_APP_VERSION`).
- Compose uses root `.env` (ports, MySQL values, API URL, image tags).

### Option 1: Run services directly (recommended for development)
1. Start MySQL (or use your own MySQL):
```bash
docker run -d --name rps-mysql \
  -e MYSQL_ROOT_PASSWORD=your_root_password \
  -e MYSQL_DATABASE=rps \
  -e MYSQL_USER=appuser \
  -e MYSQL_PASSWORD=your_app_password \
  -p 3306:3306 \
  mysql:8.0
```
2. Backend:
```bash
cd backend
npm install
npm run dev
```
3. Frontend:
```bash
cd frontend
npm install
npm run dev
```
4. Open frontend at `http://localhost:5173`.

### Option 2: Full Docker Compose stack
`docker-compose.yml` expects image references for backend and frontend (`BACKEND_IMAGE`, `FRONTEND_IMAGE`). Build/pull images first, then run:
```bash
touch init.sql
docker compose up -d
```

## Tests
Backend:
```bash
cd backend
npm test
npm run test:coverage
```

Frontend:
```bash
cd frontend
npm test
npm run test:coverage
```

## Jenkins CI/CD Pipeline
Pipeline stages in `Jenkinsfile`:
1. Checkout and image tagging (`BUILD_NUMBER` + short commit SHA)
2. Docker environment check
3. Secret scan (`gitleaks`)
4. Unit tests with coverage (backend + frontend)
5. Snyk dependency scan
6. Trivy filesystem scan (vuln, misconfig, secret)
7. SBOM generation (Syft, CycloneDX JSON)
8. SonarQube/SonarCloud analysis
9. Build and push backend/frontend images to ECR
10. Render and register new ECS task definition
11. Update ECS service (rolling, with optional CodeDeploy path)
12. Health checks
13. Verify CloudWatch log activity and alarm presence

## Terraform Infrastructure
Root Terraform (`terraform/`) provisions:
- VPC + public subnets + IGW + ALB
- ECS cluster/task/service + CloudWatch log groups
- RDS MySQL + Secrets Manager credential secret
- Jenkins least-privilege IAM policy for ECS deploy operations
- Optional CodeDeploy resources for ECS blue/green

### Apply Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Optional bootstrap for state bucket:
```bash
cd terraform/terraform-bootstrap
terraform init
terraform apply
```

## Security Controls
- Pre-commit secret scanning via `.githooks/pre-commit` (gitleaks)
- CI secret scan gate (`gitleaks`)
- Dependency scanning (`snyk`)
- IaC/app scan (`trivy`)
- SBOM generation (`syft`)
- Static analysis and quality gate (`sonar-scanner`)

Enable local hooks:
```bash
./scripts/install-git-hooks.sh
```

Manual gitleaks scan:
```bash
docker run --rm -v "$(pwd):/repo" -w /repo ghcr.io/gitleaks/gitleaks:latest \
  detect --source . --no-git --redact --config /repo/.gitleaks.toml --exit-code 1
```

## Important Notes
- Do not commit real credentials. Use environment variables, Jenkins credentials, and AWS Secrets Manager.
- Review `terraform/terraform.tfvars` before applying in any shared or production account.
- The deployment currently defaults to ECS rolling updates. Blue/green support is scaffolded and can be enabled through Terraform and Jenkins environment flags.
