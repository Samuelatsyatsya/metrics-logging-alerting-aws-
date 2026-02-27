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
                        docker run --rm \
                            -v "${WORKSPACE}:/repo" \
                            -w /repo \
                            ghcr.io/gitleaks/gitleaks:latest \
                            detect --source . --no-git --redact --config /repo/.gitleaks.toml --exit-code 1
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
                        aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
                        aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
                        aws configure set region ${AWS_REGION}
                    '''
                    
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_BACKEND_REPO%/*} || {
                            echo "ECR login failed!"
                            exit 1
                        }
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
        
        stage('Setup EC2') {
            steps {
                script {
                    sh '''
                        ssh -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY} ${EC2_USER}@${EC2_HOST} "
                            # Install Docker if not exists
                            if ! command -v docker &> /dev/null; then
                                echo 'Installing Docker...'
                                curl -fsSL https://get.docker.com -o get-docker.sh
                                sudo sh get-docker.sh
                                sudo usermod -aG docker ubuntu
                                rm -f get-docker.sh
                            fi
                            
                            # Install Docker Compose if not exists
                            if ! command -v docker-compose &> /dev/null; then
                                echo 'Installing Docker Compose...'
                                sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m) -o /usr/local/bin/docker-compose
                                sudo chmod +x /usr/local/bin/docker-compose
                            fi
                            
                            # Wait for apt lock to be released and install unzip
                            if ! command -v unzip &> /dev/null; then
                                echo 'Waiting for apt lock...'
                                while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
                                    echo 'Waiting for other apt process to finish...'
                                    sleep 5
                                done
                                
                                echo 'Installing unzip...'
                                sudo apt-get update -qq
                                sudo apt-get install -y -qq unzip
                            fi
                            
                            # Install AWS CLI v2 if not exists
                            if ! command -v aws &> /dev/null; then
                                echo 'Installing AWS CLI v2...'
                                cd /tmp
                                curl -s https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o awscliv2.zip
                                unzip -q awscliv2.zip
                                sudo ./aws/install
                                rm -rf aws awscliv2.zip
                            fi
                            
                            # Create app directory
                            mkdir -p /home/ubuntu/rock-paper-scissors
                            
                            echo 'Setup complete'
                            docker --version
                            docker-compose --version
                            aws --version
                        "
                    '''
                }
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                script {
                    sh '''
                        # Copy docker-compose file to EC2
                        scp -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY} \
                            docker-compose.yml ${EC2_USER}@${EC2_HOST}:/home/${EC2_USER}/rock-paper-scissors/
                    '''
                    
                    sh '''
                        ssh -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY} ${EC2_USER}@${EC2_HOST} "
                            cd /home/${EC2_USER}/rock-paper-scissors
                            
                            # Create .env file from Jenkins credentials
                            cat > .env << 'ENVEOF'
# Database Configuration
MYSQL_PORT=''' + env.MYSQL_PORT + '''
MYSQL_ROOT_PASSWORD=''' + env.MYSQL_ROOT_PASSWORD + '''
MYSQL_DATABASE=''' + env.MYSQL_DATABASE + '''
MYSQL_USER=''' + env.MYSQL_USER + '''
MYSQL_PASSWORD=''' + env.MYSQL_PASSWORD + '''

# Backend Configuration
BACKEND_IMAGE=''' + env.ECR_BACKEND_REPO + ''':latest
BACKEND_PORT=''' + env.BACKEND_PORT + '''
NODE_ENV=''' + env.NODE_ENV + '''
DB_HOST=''' + env.DB_HOST + '''
DB_PORT=''' + env.MYSQL_PORT + '''
DB_DIALECT=''' + env.DB_DIALECT + '''

# Frontend Configuration
FRONTEND_IMAGE=''' + env.ECR_FRONTEND_REPO + ''':latest
FRONTEND_PORT=''' + env.FRONTEND_PORT + '''
VITE_API_URL=''' + env.VITE_API_URL + '''
ENVEOF
                            
                            # Secure the .env file
                            chmod 600 .env
                            
                            # Configure AWS CLI on EC2
                            aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
                            aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
                            aws configure set region ${AWS_REGION}
                            
                            # Login to ECR
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_BACKEND_REPO%/*} || {
                                echo "ECR login on EC2 failed!"
                                exit 1
                            }
                            
                            # Pull latest images
                            echo "Pulling backend image: ${ECR_BACKEND_REPO}:latest"
                            docker pull ${ECR_BACKEND_REPO}:latest || {
                                echo "Failed to pull backend image"
                                exit 1
                            }
                            
                            echo "Pulling frontend image: ${ECR_FRONTEND_REPO}:latest"
                            docker pull ${ECR_FRONTEND_REPO}:latest || {
                                echo "Failed to pull frontend image"
                                exit 1
                            }
                            
                            # Verify images exist
                            echo "Verifying images..."
                            docker image ls | grep -E 'backend|frontend' || {
                                echo "Images not found after pull!"
                                exit 1
                            }
                            
                            echo ".env file contents:"
                            cat .env
                            
                            # Stop and remove all containers managed by compose
                            docker compose rm -f || true
                            
                            # Remove the existing network
                            docker network rm rps-app_app-network 2>/dev/null || true
                            
                            # Wait a moment for cleanup
                            sleep 5
                            
                            # Verify images one more time before compose up
                            echo "Images available before docker compose up:"
                            docker image ls
                            
                            # Start new containers with verbose output
                            docker compose up -d --no-color
                            
                            # Clean up old images
                            docker image prune -af
                        "
                    '''
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    sh '''
                        sleep 30
                        ssh -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY} ${EC2_USER}@${EC2_HOST} '
                            BACKEND_PORT=''' + env.BACKEND_PORT + '''
                            FRONTEND_PORT=''' + env.FRONTEND_PORT + '''
                            
                            echo "Checking container status..."
                            docker ps -a
                            
                            echo "Backend container logs (last 100 lines):"
                            docker logs rps-backend 2>&1 | tail -100
                            
                            echo "Checking if ports are listening..."
                            ss -tlnp 2>/dev/null || netstat -tlnp
                            
                            # Check backend health with retry
                            MAX_RETRIES=10
                            RETRY_COUNT=0
                            until [ $RETRY_COUNT -ge $MAX_RETRIES ]; do
                                echo "Health check attempt $((RETRY_COUNT + 1))/$MAX_RETRIES..."
                                if curl -f http://localhost:${BACKEND_PORT}/health 2>/dev/null; then
                                    echo "Backend is healthy"
                                    break
                                fi
                                RETRY_COUNT=$((RETRY_COUNT + 1))
                                if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                                    sleep 5
                                fi
                            done
                            
                            if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
                                echo "Backend health check failed after $MAX_RETRIES attempts"
                                exit 1
                            fi
                            
                            # Check frontend
                            if curl -f http://localhost:${FRONTEND_PORT} 2>/dev/null; then
                                echo "Frontend is healthy"
                            else
                                echo "Frontend health check failed"
                                exit 1
                            fi
                            
                            # Check metrics endpoint
                            if curl -f http://localhost:${BACKEND_PORT}/metrics 2>/dev/null; then
                                echo "Metrics endpoint is healthy"
                            else
                                echo "Metrics endpoint check failed"
                                exit 1
                            fi
                        '
                    '''
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline succeeded!'
            echo "Application deployed to: http://${EC2_HOST}"
            echo "Backend API: http://${EC2_HOST}:${BACKEND_PORT}"
            echo "Metrics: http://${EC2_HOST}:${BACKEND_PORT}/metrics"
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            sh 'docker system prune -f || true'
        }
    }
}
