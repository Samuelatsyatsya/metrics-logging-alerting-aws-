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
        
        stage('Build and Push Images') {
            steps {
                script {
                    sh '''
                        aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
                        aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
                        aws configure set region ${AWS_REGION}
                    '''
                    
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_BACKEND_REPO%/*}
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
                        
                        # Copy .env file if exists
                        if [ -f .env.production ]; then
                            scp -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY} \
                                .env.production ${EC2_USER}@${EC2_HOST}:/home/${EC2_USER}/rock-paper-scissors/.env
                        fi
                    '''
                    
                    sh '''
                        ssh -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY} ${EC2_USER}@${EC2_HOST} "
                            cd /home/${EC2_USER}/rock-paper-scissors
                            
                            # Configure AWS CLI on EC2
                            aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
                            aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}
                            aws configure set region ${AWS_REGION}
                            
                            # Login to ECR
                            aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_BACKEND_REPO%/*}
                            
                            # Pull latest images
                            docker pull ${ECR_BACKEND_REPO}:latest
                            docker pull ${ECR_FRONTEND_REPO}:latest
                            
                            # Stop old containers
                            docker compose down || true
                            
                            # Start new containers with environment variables
                            export BACKEND_IMAGE=${ECR_BACKEND_REPO}:latest
                            export FRONTEND_IMAGE=${ECR_FRONTEND_REPO}:latest
                            docker compose up -d
                            
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
                        sleep 15
                        ssh -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY} ${EC2_USER}@${EC2_HOST} '
                            # Check backend health
                            if curl -f http://localhost:5000/health; then
                                echo "Backend is healthy"
                            else
                                echo "Backend health check failed"
                                exit 1
                            fi
                            
                            # Check frontend
                            if curl -f http://localhost:80; then
                                echo "Frontend is healthy"
                            else
                                echo "Frontend health check failed"
                                exit 1
                            fi
                            
                            # Check metrics endpoint
                            if curl -f http://localhost:5000/metrics; then
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
            echo "Backend API: http://${EC2_HOST}:5000"
            echo "Metrics: http://${EC2_HOST}:5000/metrics"
        }
        failure {
            echo 'Pipeline failed!'
        }
        always {
            sh 'docker system prune -f || true'
        }
    }
}
