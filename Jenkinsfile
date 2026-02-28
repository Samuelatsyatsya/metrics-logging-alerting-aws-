pipeline {
    agent any
    
    triggers {
        githubPush()
    }
    
    environment {
        AWS_REGION = credentials('AWS_REGION')
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        ECR_BACKEND_REPO = credentials('ECR_BACKEND_REPO')
        ECR_FRONTEND_REPO = credentials('ECR_FRONTEND_REPO')
        VITE_API_URL = credentials('VITE_API_URL')
        EC2_HOST = credentials('EC2_HOST')
        SSH_PRIVATE_KEY = credentials('SSH_PRIVATE_KEY')
        EC2_USER = credentials('EC2_USER')
        
        // Database credentials
        MYSQL_ROOT_PASSWORD = credentials('MYSQL_ROOT_PASSWORD')
        MYSQL_PASSWORD = credentials('MYSQL_PASSWORD')
        MYSQL_DATABASE = credentials('MYSQL_DATABASE')
        MYSQL_PORT = credentials('MYSQL_PORT')
        MYSQL_USER = credentials('MYSQL_USER')
        
        // Port configurations
        BACKEND_PORT = credentials('BACKEND_PORT')
        FRONTEND_PORT = credentials('FRONTEND_PORT')
        DB_HOST = credentials('DB_HOST')
        DB_PORT = credentials('DB_PORT')
        DB_DIALECT = credentials('DB_DIALECT')

        // Node environment
        NODE_ENV = credentials('NODE_ENV')

        // SonarQube
        SONAR_HOST_URL = credentials('SONAR_HOST_URL')
        SONAR_TOKEN = credentials('SONAR_TOKEN')
        SONAR_ORGANIZATION = credentials('SONAR_ORGANIZATION')

        // Snyk
        SNYK_TOKEN = credentials('SNYK_TOKEN')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT_SHORT}"
                }
            }
        }
        
        stage('Setup Docker') {
            steps {
                script {
                    sh '''
                        # Check if docker socket exists
                        if [ ! -S /var/run/docker.sock ]; then
                            echo "WARNING: Docker socket not found at /var/run/docker.sock"
                            echo "Jenkins may be running without docker socket mount"
                            exit 0
                        fi
                        
                        # Try to access docker
                        if docker ps > /dev/null 2>&1; then
                            echo "Docker is accessible"
                            docker --version
                            exit 0
                        fi
                        
                        # Docker socket exists but not accessible to jenkins user
                        echo "WARNING: Docker socket exists but not accessible to jenkins user"
                        echo "Attempting to fix permissions..."
                        
                        # Try to fix permissions
                        if chmod 666 /var/run/docker.sock 2>/dev/null; then
                            echo "Fixed docker socket permissions"
                        else
                            echo "WARNING: Could not fix docker socket permissions (may need sudo on host)"
                        fi
                        
                        # Try again
                        if docker ps > /dev/null 2>&1; then
                            echo "Docker is now accessible"
                            docker --version
                            exit 0
                        else
                            echo "WARNING: Docker still not accessible, continuing anyway"
                            echo "Build stage will fail if Docker is required"
                            exit 0
                        fi
                    '''
                }
            }
        }

        stage('Secret Scan (Gitleaks)') {
            steps {
                script {
                    sh '''
                        if ! docker ps > /dev/null 2>&1; then
                            echo "ERROR: Docker is not accessible for gitleaks scan"
                            exit 1
                        fi

                        echo "Running gitleaks scan..."
                        SCAN_CONTAINER=""
                        cleanup() {
                            if [ -n "${SCAN_CONTAINER}" ]; then
                                docker rm -f "${SCAN_CONTAINER}" >/dev/null 2>&1 || true
                            fi
                        }
                        trap cleanup EXIT

                        if [ -f "${WORKSPACE}/.gitleaks.toml" ]; then
                            echo "Using repository gitleaks config: .gitleaks.toml"
                            SCAN_CONTAINER="$(docker create -w /repo ghcr.io/gitleaks/gitleaks:latest \
                                detect --source . --no-git --redact --config .gitleaks.toml --exit-code 1)"
                        else
                            echo "WARNING: .gitleaks.toml not found in workspace, using default gitleaks rules"
                            SCAN_CONTAINER="$(docker create -w /repo ghcr.io/gitleaks/gitleaks:latest \
                                detect --source . --no-git --redact --exit-code 1)"
                        fi

                        # Avoid bind-mount path issues when Jenkins runs in a container.
                        docker cp "${WORKSPACE}/." "${SCAN_CONTAINER}:/repo"
                        docker start -a "${SCAN_CONTAINER}"
                    '''
                }
            }
        }

        stage('Test and Coverage') {
            steps {
                script {
                    sh '''
                        if ! docker ps > /dev/null 2>&1; then
                            echo "ERROR: Docker is not accessible for test execution"
                            exit 1
                        fi

                        echo "Running backend and frontend tests with coverage..."
                        TEST_CONTAINER=""
                        cleanup() {
                            if [ -n "${TEST_CONTAINER}" ]; then
                                docker rm -f "${TEST_CONTAINER}" >/dev/null 2>&1 || true
                            fi
                        }
                        trap cleanup EXIT

                        TEST_CONTAINER="$(docker create -w /workspace node:20-bookworm sh -lc '
                            set -e
                            cd /workspace/backend
                            npm install --no-audit --no-fund
                            npm run test:coverage

                            cd /workspace/frontend
                            npm install --no-audit --no-fund
                            npm run test:coverage
                        ')"

                        # Avoid bind-mount path issues when Jenkins runs in a container.
                        docker cp "${WORKSPACE}/." "${TEST_CONTAINER}:/workspace"
                        docker start -a "${TEST_CONTAINER}"

                        mkdir -p "${WORKSPACE}/backend/coverage" "${WORKSPACE}/frontend/coverage"
                        docker cp "${TEST_CONTAINER}:/workspace/backend/coverage/lcov.info" "${WORKSPACE}/backend/coverage/lcov.info"
                        docker cp "${TEST_CONTAINER}:/workspace/frontend/coverage/lcov.info" "${WORKSPACE}/frontend/coverage/lcov.info"
                    '''
                }
            }
        }

        stage('Snyk Security Scan') {
            steps {
                script {
                    sh '''
                        if ! docker ps > /dev/null 2>&1; then
                            echo "ERROR: Docker is not accessible for Snyk scan"
                            exit 1
                        fi

                        if [ -z "${SNYK_TOKEN}" ]; then
                            echo "ERROR: SNYK_TOKEN credential is required"
                            exit 1
                        fi

                        echo "Running Snyk dependency scan..."
                        SNYK_ORG_ARG=""
                        if [ -n "${SNYK_ORG:-}" ]; then
                            SNYK_ORG_ARG="--org=${SNYK_ORG}"
                            echo "Using Snyk organization: ${SNYK_ORG}"
                        else
                            echo "SNYK_ORG not set, using token default organization"
                        fi

                        SCAN_CONTAINER=""
                        cleanup() {
                            if [ -n "${SCAN_CONTAINER}" ]; then
                                docker rm -f "${SCAN_CONTAINER}" >/dev/null 2>&1 || true
                            fi
                        }
                        trap cleanup EXIT

                        SCAN_CONTAINER="$(docker create \
                            -e SNYK_TOKEN="${SNYK_TOKEN}" \
                            -w /workspace \
                            node:20-bookworm \
                            sh -lc '
                                set -e
                                npm install -g --no-audit --no-fund snyk
                                snyk test --all-projects --severity-threshold=high --detection-depth=5 '"${SNYK_ORG_ARG}"' --json-file-output=/workspace/snyk-results.json
                            ')"

                        # Avoid bind-mount path issues when Jenkins runs in a container.
                        docker cp "${WORKSPACE}/." "${SCAN_CONTAINER}:/workspace"

                        set +e
                        docker start -a "${SCAN_CONTAINER}"
                        SNYK_EXIT_CODE=$?
                        set -e

                        docker cp "${SCAN_CONTAINER}:/workspace/snyk-results.json" "${WORKSPACE}/snyk-results.json" || true

                        if [ "${SNYK_EXIT_CODE}" -ne 0 ]; then
                            echo "Snyk scan failed with exit code ${SNYK_EXIT_CODE}"
                            exit "${SNYK_EXIT_CODE}"
                        fi
                    '''
                }
            }
        }

        stage('Trivy Security Scan') {
            steps {
                script {
                    sh '''
                        if ! docker ps > /dev/null 2>&1; then
                            echo "ERROR: Docker is not accessible for Trivy scan"
                            exit 1
                        fi

                        echo "Running Trivy filesystem scan..."
                        TRIVY_IMAGE=""
                        for CANDIDATE in aquasec/trivy:latest aquasec/trivy:0.57.1; do
                            if docker pull "${CANDIDATE}" >/dev/null 2>&1; then
                                TRIVY_IMAGE="${CANDIDATE}"
                                break
                            fi
                        done

                        if [ -z "${TRIVY_IMAGE}" ]; then
                            echo "ERROR: Unable to pull a supported Trivy image"
                            exit 1
                        fi

                        SCAN_CONTAINER=""
                        cleanup() {
                            if [ -n "${SCAN_CONTAINER}" ]; then
                                docker rm -f "${SCAN_CONTAINER}" >/dev/null 2>&1 || true
                            fi
                        }
                        trap cleanup EXIT

                        SCAN_CONTAINER="$(docker create \
                            -w /workspace \
                            "${TRIVY_IMAGE}" \
                            filesystem \
                            --scanners vuln,misconfig,secret \
                            --severity HIGH,CRITICAL \
                            --ignore-unfixed \
                            --no-progress \
                            --timeout 10m \
                            --format json \
                            --output /workspace/trivy-results.json \
                            --exit-code 1 \
                            /workspace)"

                        # Avoid bind-mount path issues when Jenkins runs in a container.
                        docker cp "${WORKSPACE}/." "${SCAN_CONTAINER}:/workspace"

                        set +e
                        docker start -a "${SCAN_CONTAINER}"
                        TRIVY_EXIT_CODE=$?
                        set -e

                        docker cp "${SCAN_CONTAINER}:/workspace/trivy-results.json" "${WORKSPACE}/trivy-results.json" || true

                        if [ -f "${WORKSPACE}/trivy-results.json" ]; then
                            echo "Trivy finding summary (HIGH/CRITICAL):"
                            if command -v jq >/dev/null 2>&1; then
                                jq -r '
                                  .Results[]? as $r
                                  | ($r.Vulnerabilities[]? | "VULN\t\\(.Severity)\t\\(.VulnerabilityID)\t\\($r.Target)\t\\(.PkgName)@\\(.InstalledVersion)\tfix:\\(.FixedVersion // "n/a")"),
                                    ($r.Misconfigurations[]? | "MISCONFIG\t\\(.Severity)\t\\(.ID)\t\\($r.Target)\t\\(.Title)\tresolution:\\(.Resolution // "n/a")"),
                                    ($r.Secrets[]? | "SECRET\t\\(.Severity)\t\\(.RuleID)\t\\($r.Target)\t\\(.Title)\tline:\\(.StartLine // "n/a")")
                                ' "${WORKSPACE}/trivy-results.json" | \
                                awk -F'\t' '$2=="HIGH" || $2=="CRITICAL" {print}' || true
                            else
                                JQ_IMAGE=""
                                for CANDIDATE in ghcr.io/jqlang/jq:latest imega/jq:latest; do
                                    if docker pull "${CANDIDATE}" >/dev/null 2>&1; then
                                        JQ_IMAGE="${CANDIDATE}"
                                        break
                                    fi
                                done

                                if [ -n "${JQ_IMAGE}" ]; then
                                    echo "Local jq not found; using jq from Docker image ${JQ_IMAGE}"
                                    JQ_CONTAINER="$(docker create -w /workspace "${JQ_IMAGE}" \
                                        -r '
                                          .Results[]? as $r
                                          | ($r.Vulnerabilities[]? | "VULN\t\\(.Severity)\t\\(.VulnerabilityID)\t\\($r.Target)\t\\(.PkgName)@\\(.InstalledVersion)\tfix:\\(.FixedVersion // "n/a")"),
                                            ($r.Misconfigurations[]? | "MISCONFIG\t\\(.Severity)\t\\(.ID)\t\\($r.Target)\t\\(.Title)\tresolution:\\(.Resolution // "n/a")"),
                                            ($r.Secrets[]? | "SECRET\t\\(.Severity)\t\\(.RuleID)\t\\($r.Target)\t\\(.Title)\tline:\\(.StartLine // "n/a")")
                                        ' /workspace/trivy-results.json)"
                                    docker cp "${WORKSPACE}/trivy-results.json" "${JQ_CONTAINER}:/workspace/trivy-results.json"
                                    docker start -a "${JQ_CONTAINER}" | \
                                    awk -F'\t' '$2=="HIGH" || $2=="CRITICAL" {print}' || true
                                    docker rm -f "${JQ_CONTAINER}" >/dev/null 2>&1 || true
                                else
                                    echo "WARNING: jq is unavailable and no jq image could be pulled; skipping Trivy summary parsing."
                                fi
                            fi
                        else
                            echo "WARNING: trivy-results.json was not found after scan."
                        fi

                        if [ "${TRIVY_EXIT_CODE}" -ne 0 ]; then
                            echo "Trivy scan failed with exit code ${TRIVY_EXIT_CODE}"
                            echo "See ${WORKSPACE}/trivy-results.json for full details."
                            exit "${TRIVY_EXIT_CODE}"
                        fi
                    '''
                }
            }
        }

        stage('SBOM Generation (Syft)') {
            steps {
                script {
                    sh '''
                        if ! docker ps > /dev/null 2>&1; then
                            echo "ERROR: Docker is not accessible for Syft SBOM generation"
                            exit 1
                        fi

                        echo "Generating SBOM with Syft..."
                        SYFT_IMAGE=""
                        for CANDIDATE in anchore/syft:latest anchore/syft:v1.20.0; do
                            if docker pull "${CANDIDATE}" >/dev/null 2>&1; then
                                SYFT_IMAGE="${CANDIDATE}"
                                break
                            fi
                        done

                        if [ -z "${SYFT_IMAGE}" ]; then
                            echo "ERROR: Unable to pull a supported Syft image"
                            exit 1
                        fi

                        SBOM_CONTAINER=""
                        cleanup() {
                            if [ -n "${SBOM_CONTAINER}" ]; then
                                docker rm -f "${SBOM_CONTAINER}" >/dev/null 2>&1 || true
                            fi
                        }
                        trap cleanup EXIT

                        SBOM_CONTAINER="$(docker create \
                            -w /workspace \
                            "${SYFT_IMAGE}" \
                            dir:/workspace \
                            -o cyclonedx-json=/workspace/sbom-cyclonedx.json)"

                        # Avoid bind-mount path issues when Jenkins runs in a container.
                        docker cp "${WORKSPACE}/." "${SBOM_CONTAINER}:/workspace"
                        docker start -a "${SBOM_CONTAINER}"

                        docker cp "${SBOM_CONTAINER}:/workspace/sbom-cyclonedx.json" "${WORKSPACE}/sbom-cyclonedx.json"
                        echo "SBOM generated: ${WORKSPACE}/sbom-cyclonedx.json"
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    sh '''
                        if ! docker ps > /dev/null 2>&1; then
                            echo "ERROR: Docker is not accessible for SonarQube scan"
                            exit 1
                        fi

                        if [ -z "${SONAR_HOST_URL}" ] || [ -z "${SONAR_TOKEN}" ]; then
                            echo "ERROR: SONAR_HOST_URL and SONAR_TOKEN credentials are required"
                            exit 1
                        fi

                        if [ -z "${SONAR_ORGANIZATION}" ]; then
                            echo "ERROR: SONAR_ORGANIZATION credential is required for SonarCloud"
                            exit 1
                        fi

                        echo "Running SonarQube analysis..."
                        SONAR_PROJECT_KEY_VALUE="${SONAR_PROJECT_KEY:-$(echo "${JOB_NAME}" | tr '/ ' '--')}"
                        SONAR_PROJECT_NAME_VALUE="${SONAR_PROJECT_NAME:-${JOB_NAME}}"
                        SCAN_CONTAINER=""

                        cleanup() {
                            if [ -n "${SCAN_CONTAINER}" ]; then
                                docker rm -f "${SCAN_CONTAINER}" >/dev/null 2>&1 || true
                            fi
                        }
                        trap cleanup EXIT

                        SCAN_CONTAINER="$(docker create -w /usr/src sonarsource/sonar-scanner-cli:latest \
                            -Dsonar.host.url="${SONAR_HOST_URL}" \
                            -Dsonar.token="${SONAR_TOKEN}" \
                            -Dsonar.organization="${SONAR_ORGANIZATION}" \
                            -Dsonar.projectKey="${SONAR_PROJECT_KEY_VALUE}" \
                            -Dsonar.projectName="${SONAR_PROJECT_NAME_VALUE}" \
                            -Dsonar.projectVersion="${BUILD_NUMBER}" \
                            -Dsonar.qualitygate.wait=true)"

                        # Avoid bind-mount path issues when Jenkins runs in a container.
                        docker cp "${WORKSPACE}/." "${SCAN_CONTAINER}:/usr/src"
                        docker start -a "${SCAN_CONTAINER}"
                    '''
                }
            }
        }

        stage('Build and Push Images') {
            steps {
                script {
                    // First check if docker is available
                    sh '''
                        if ! docker ps > /dev/null 2>&1; then
                            echo "ERROR: Docker is not accessible"
                            echo "Ensure Jenkins container has Docker socket mounted:"
                            echo "  docker stop jenkins"
                            echo "  docker run -d -v /var/run/docker.sock:/var/run/docker.sock ..."
                            exit 1
                        fi
                    '''
                    
                    sh '''
                        ecr_login() {
                            REGISTRY="$1"
                            echo "Logging in to ECR registry: ${REGISTRY}"

                            AWS_CLI_IMAGE=""
                            for CANDIDATE in public.ecr.aws/aws-cli/aws-cli:latest amazon/aws-cli:latest; do
                                if docker pull "${CANDIDATE}" >/dev/null 2>&1; then
                                    AWS_CLI_IMAGE="${CANDIDATE}"
                                    break
                                fi
                            done

                            if [ -z "${AWS_CLI_IMAGE}" ]; then
                                echo "Unable to pull a supported AWS CLI image for ECR login"
                                exit 1
                            fi

                            PASSWORD="$(docker run --rm \
                                -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
                                -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
                                -e AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN:-}" \
                                -e AWS_DEFAULT_REGION="${AWS_REGION}" \
                                "${AWS_CLI_IMAGE}" \
                                ecr get-login-password --region "${AWS_REGION}")" || {
                                echo "Failed to obtain ECR login password from AWS CLI container"
                                exit 1
                            }

                            echo "${PASSWORD}" | docker login --username AWS --password-stdin "${REGISTRY}" || {
                                echo "ECR login failed for ${REGISTRY}"
                                exit 1
                            }
                            PASSWORD=""
                        }

                        ecr_login "${ECR_BACKEND_REPO%/*}"

                        if [ "${ECR_FRONTEND_REPO%/*}" != "${ECR_BACKEND_REPO%/*}" ]; then
                            ecr_login "${ECR_FRONTEND_REPO%/*}"
                        fi
                    '''
                    
                    sh '''
                        docker build \
                            -t "${ECR_BACKEND_REPO}:${IMAGE_TAG}" \
                            -t "${ECR_BACKEND_REPO}:latest" \
                            ./backend
                        
                        docker push "${ECR_BACKEND_REPO}:${IMAGE_TAG}"
                        docker push "${ECR_BACKEND_REPO}:latest"
                    '''
                    
                    sh '''
                        docker build \
                            --build-arg VITE_API_URL="${VITE_API_URL}" \
                            -t "${ECR_FRONTEND_REPO}:${IMAGE_TAG}" \
                            -t "${ECR_FRONTEND_REPO}:latest" \
                            ./frontend
                        
                        docker push "${ECR_FRONTEND_REPO}:${IMAGE_TAG}"
                        docker push "${ECR_FRONTEND_REPO}:latest"
                    '''
                }
            }
        }
        
        stage('Render ECS Task Definition') {
            steps {
                script {
                    sh '''
                        if ! docker ps > /dev/null 2>&1; then
                            echo "ERROR: Docker is not accessible for ECS task rendering"
                            exit 1
                        fi

                        if [ -z "${ECS_CLUSTER:-}" ] || [ -z "${ECS_SERVICE:-}" ]; then
                            echo "ERROR: ECS_CLUSTER and ECS_SERVICE environment variables are required"
                            exit 1
                        fi

                        AWS_CLI_IMAGE=""
                        for CANDIDATE in public.ecr.aws/aws-cli/aws-cli:latest amazon/aws-cli:latest; do
                            if docker pull "${CANDIDATE}" >/dev/null 2>&1; then
                                AWS_CLI_IMAGE="${CANDIDATE}"
                                break
                            fi
                        done

                        if [ -z "${AWS_CLI_IMAGE}" ]; then
                            echo "ERROR: Unable to pull a supported AWS CLI image"
                            exit 1
                        fi

                        CURRENT_TASKDEF_ARN="$(docker run --rm \
                            -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
                            -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
                            -e AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN:-}" \
                            -e AWS_DEFAULT_REGION="${AWS_REGION}" \
                            "${AWS_CLI_IMAGE}" \
                            ecs describe-services \
                                --cluster "${ECS_CLUSTER}" \
                                --services "${ECS_SERVICE}" \
                                --query 'services[0].taskDefinition' \
                                --output text)"

                        if [ -z "${CURRENT_TASKDEF_ARN}" ] || [ "${CURRENT_TASKDEF_ARN}" = "None" ]; then
                            echo "ERROR: Could not resolve current task definition from ECS service"
                            exit 1
                        fi

                        docker run --rm \
                            -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
                            -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
                            -e AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN:-}" \
                            -e AWS_DEFAULT_REGION="${AWS_REGION}" \
                            "${AWS_CLI_IMAGE}" \
                            ecs describe-task-definition \
                                --task-definition "${CURRENT_TASKDEF_ARN}" \
                                --query 'taskDefinition' \
                                --output json > "${WORKSPACE}/taskdef.base.json"

                        BACKEND_CONTAINER_NAME_VALUE="${ECS_BACKEND_CONTAINER_NAME:-backend}"
                        FRONTEND_CONTAINER_NAME_VALUE="${ECS_FRONTEND_CONTAINER_NAME:-frontend}"

                        jq \
                          --arg backendImage "${ECR_BACKEND_REPO}:${IMAGE_TAG}" \
                          --arg frontendImage "${ECR_FRONTEND_REPO}:${IMAGE_TAG}" \
                          --arg backendName "${BACKEND_CONTAINER_NAME_VALUE}" \
                          --arg frontendName "${FRONTEND_CONTAINER_NAME_VALUE}" \
                          '
                            del(
                              .taskDefinitionArn,
                              .revision,
                              .status,
                              .requiresAttributes,
                              .compatibilities,
                              .registeredAt,
                              .registeredBy,
                              .deregisteredAt
                            )
                            | .containerDefinitions |= map(
                                if .name == $backendName then .image = $backendImage
                                elif .name == $frontendName then .image = $frontendImage
                                elif (.name | test("backend"; "i")) then .image = $backendImage
                                elif (.name | test("frontend"; "i")) then .image = $frontendImage
                                else .
                                end
                              )
                          ' "${WORKSPACE}/taskdef.base.json" > "${WORKSPACE}/taskdef.rendered.json"

                        echo "Rendered task definition: ${WORKSPACE}/taskdef.rendered.json"
                    '''
                }
            }
        }

        stage('Register ECS Task Definition') {
            steps {
                script {
                    sh '''
                        if [ ! -f "${WORKSPACE}/taskdef.rendered.json" ]; then
                            echo "ERROR: taskdef.rendered.json not found"
                            exit 1
                        fi

                        AWS_CLI_IMAGE=""
                        for CANDIDATE in public.ecr.aws/aws-cli/aws-cli:latest amazon/aws-cli:latest; do
                            if docker pull "${CANDIDATE}" >/dev/null 2>&1; then
                                AWS_CLI_IMAGE="${CANDIDATE}"
                                break
                            fi
                        done

                        if [ -z "${AWS_CLI_IMAGE}" ]; then
                            echo "ERROR: Unable to pull a supported AWS CLI image"
                            exit 1
                        fi

                        REGISTER_CONTAINER=""
                        cleanup() {
                            if [ -n "${REGISTER_CONTAINER}" ]; then
                                docker rm -f "${REGISTER_CONTAINER}" >/dev/null 2>&1 || true
                            fi
                        }
                        trap cleanup EXIT

                        REGISTER_CONTAINER="$(docker create \
                            --entrypoint sh \
                            -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
                            -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
                            -e AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN:-}" \
                            -e AWS_DEFAULT_REGION="${AWS_REGION}" \
                            -w /workspace \
                            "${AWS_CLI_IMAGE}" \
                            -lc 'aws ecs register-task-definition --cli-input-json file://taskdef.rendered.json --query "taskDefinition.taskDefinitionArn" --output text > /workspace/new_taskdef_arn.txt')"

                        docker cp "${WORKSPACE}/taskdef.rendered.json" "${REGISTER_CONTAINER}:/workspace/taskdef.rendered.json"
                        docker start -a "${REGISTER_CONTAINER}"
                        docker cp "${REGISTER_CONTAINER}:/workspace/new_taskdef_arn.txt" "${WORKSPACE}/new_taskdef_arn.txt"

                        echo "Registered task definition ARN:"
                        cat "${WORKSPACE}/new_taskdef_arn.txt"
                    '''
                }
            }
        }

        stage('Update ECS Service') {
            steps {
                script {
                    sh '''
                        if [ -z "${ECS_CLUSTER:-}" ] || [ -z "${ECS_SERVICE:-}" ]; then
                            echo "ERROR: ECS_CLUSTER and ECS_SERVICE environment variables are required"
                            exit 1
                        fi

                        if [ ! -f "${WORKSPACE}/new_taskdef_arn.txt" ]; then
                            echo "ERROR: new_taskdef_arn.txt not found"
                            exit 1
                        fi

                        AWS_CLI_IMAGE=""
                        for CANDIDATE in public.ecr.aws/aws-cli/aws-cli:latest amazon/aws-cli:latest; do
                            if docker pull "${CANDIDATE}" >/dev/null 2>&1; then
                                AWS_CLI_IMAGE="${CANDIDATE}"
                                break
                            fi
                        done

                        if [ -z "${AWS_CLI_IMAGE}" ]; then
                            echo "ERROR: Unable to pull a supported AWS CLI image"
                            exit 1
                        fi

                        UPDATE_CONTAINER=""
                        cleanup() {
                            if [ -n "${UPDATE_CONTAINER}" ]; then
                                docker rm -f "${UPDATE_CONTAINER}" >/dev/null 2>&1 || true
                            fi
                        }
                        trap cleanup EXIT

                        UPDATE_CONTAINER="$(docker create \
                            --entrypoint sh \
                            -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
                            -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
                            -e AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN:-}" \
                            -e AWS_DEFAULT_REGION="${AWS_REGION}" \
                            -e ECS_CLUSTER="${ECS_CLUSTER}" \
                            -e ECS_SERVICE="${ECS_SERVICE}" \
                            -w /workspace \
                            "${AWS_CLI_IMAGE}" \
                            -lc '
                                set -e
                                NEW_TASKDEF_ARN="$(cat /workspace/new_taskdef_arn.txt)"
                                aws ecs update-service --cluster "${ECS_CLUSTER}" --service "${ECS_SERVICE}" --task-definition "${NEW_TASKDEF_ARN}" > /workspace/ecs-service-update.json
                                aws ecs wait services-stable --cluster "${ECS_CLUSTER}" --services "${ECS_SERVICE}"
                                aws ecs describe-services --cluster "${ECS_CLUSTER}" --services "${ECS_SERVICE}" --query "services[0].[status,desiredCount,runningCount,pendingCount,taskDefinition]" --output table > /workspace/ecs-service-status.txt
                            ')"

                        docker cp "${WORKSPACE}/new_taskdef_arn.txt" "${UPDATE_CONTAINER}:/workspace/new_taskdef_arn.txt"
                        docker start -a "${UPDATE_CONTAINER}"
                        docker cp "${UPDATE_CONTAINER}:/workspace/ecs-service-status.txt" "${WORKSPACE}/ecs-service-status.txt"

                        echo "ECS service status:"
                        cat "${WORKSPACE}/ecs-service-status.txt"
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    sh '''
                        if [ -z "${ECS_CLUSTER:-}" ] || [ -z "${ECS_SERVICE:-}" ]; then
                            echo "ERROR: ECS_CLUSTER and ECS_SERVICE environment variables are required"
                            exit 1
                        fi

                        AWS_CLI_IMAGE=""
                        for CANDIDATE in public.ecr.aws/aws-cli/aws-cli:latest amazon/aws-cli:latest; do
                            if docker pull "${CANDIDATE}" >/dev/null 2>&1; then
                                AWS_CLI_IMAGE="${CANDIDATE}"
                                break
                            fi
                        done

                        if [ -z "${AWS_CLI_IMAGE}" ]; then
                            echo "ERROR: Unable to pull a supported AWS CLI image"
                            exit 1
                        fi

                        SERVICE_HEALTH="$(docker run --rm \
                            -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
                            -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
                            -e AWS_SESSION_TOKEN="${AWS_SESSION_TOKEN:-}" \
                            -e AWS_DEFAULT_REGION="${AWS_REGION}" \
                            "${AWS_CLI_IMAGE}" \
                            ecs describe-services \
                                --cluster "${ECS_CLUSTER}" \
                                --services "${ECS_SERVICE}" \
                                --query 'services[0].[status,desiredCount,runningCount,pendingCount]' \
                                --output text)"

                        echo "ECS service health: ${SERVICE_HEALTH}"

                        SERVICE_STATUS="$(echo "${SERVICE_HEALTH}" | awk '{print $1}')"
                        DESIRED_COUNT="$(echo "${SERVICE_HEALTH}" | awk '{print $2}')"
                        RUNNING_COUNT="$(echo "${SERVICE_HEALTH}" | awk '{print $3}')"

                        if [ "${SERVICE_STATUS}" != "ACTIVE" ]; then
                            echo "ERROR: ECS service status is ${SERVICE_STATUS}, expected ACTIVE"
                            exit 1
                        fi

                        if [ "${RUNNING_COUNT}" -lt "${DESIRED_COUNT}" ]; then
                            echo "ERROR: ECS running tasks (${RUNNING_COUNT}) are below desired count (${DESIRED_COUNT})"
                            exit 1
                        fi

                        if [ -n "${APP_HEALTHCHECK_URL:-}" ]; then
                            echo "Checking application health endpoint: ${APP_HEALTHCHECK_URL}"
                            MAX_RETRIES=10
                            RETRY_COUNT=0
                            until [ "${RETRY_COUNT}" -ge "${MAX_RETRIES}" ]; do
                                if curl -fsS "${APP_HEALTHCHECK_URL}" >/dev/null 2>&1; then
                                    echo "Application health endpoint is reachable"
                                    break
                                fi
                                RETRY_COUNT=$((RETRY_COUNT + 1))
                                if [ "${RETRY_COUNT}" -lt "${MAX_RETRIES}" ]; then
                                    sleep 10
                                fi
                            done

                            if [ "${RETRY_COUNT}" -ge "${MAX_RETRIES}" ]; then
                                echo "ERROR: Health endpoint check failed after ${MAX_RETRIES} attempts"
                                exit 1
                            fi
                        else
                            echo "APP_HEALTHCHECK_URL not set, skipping HTTP endpoint check"
                        fi
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline succeeded!'
            echo "Application deployed via ECS service: ${ECS_CLUSTER}/${ECS_SERVICE}"
            script {
                if (env.APP_HEALTHCHECK_URL?.trim()) {
                    echo "Health endpoint: ${env.APP_HEALTHCHECK_URL}"
                }
            }
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            sh 'docker system prune -f || true'
        }
    }
}
