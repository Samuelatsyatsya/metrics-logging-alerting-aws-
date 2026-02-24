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
                        ssh -o StrictHostKeyChecking=no -i ${SSH_PRIVATE_KEY} ${EC2_USER}@${EC2_HOST} '
                            cd /home/${EC2_USER}/rock-paper-scissors
                            
                            # Configure AWS CLI on EC2
                            aws configure set aws_access_key_id '${AWS_ACCESS_KEY_ID}'
                            aws configure set aws_secret_access_key '${AWS_SECRET_ACCESS_KEY}'
                            aws configure set region '${AWS_REGION}'
                            
                            # Login to ECR
                            aws ecr get-login-password --region '${AWS_REGION}' | \
                            docker login --username AWS --password-stdin '${ECR_BACKEND_REPO%/*}'
                            
                            # Pull latest images
                            docker pull '${ECR_BACKEND_REPO}':latest
                            docker pull '${ECR_FRONTEND_REPO}':latest
                            
                            # Stop old containers
                            docker compose down || true
                            
                            # Start new containers with environment variables
                            export BACKEND_IMAGE='${ECR_BACKEND_REPO}':latest
                            export FRONTEND_IMAGE='${ECR_FRONTEND_REPO}':latest
                            docker compose up -d
                            
                            # Clean up old images
                            docker image prune -af
                        '
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
