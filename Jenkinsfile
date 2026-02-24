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
        BASTION_HOST = credentials('BASTION_HOST')
        SSH_PRIVATE_KEY = credentials('SSH_PRIVATE_KEY')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        // stage('Lint') {
        //     steps {
        //         script {
        //             sh '''
        //                 python3 -m venv venv
        //                 . venv/bin/activate
        //                 pip install ansible-lint ansible-core
        //                 ansible-galaxy collection install community.docker community.aws
        //             '''
                    
        //             sh '''
        //                 . venv/bin/activate
        //                 export ANSIBLE_ROLES_PATH=ansible/roles
        //                 ansible-lint ansible/playbooks/
        //             '''
                    
        //             sh '''
        //                 docker run --rm -i hadolint/hadolint < backend/Dockerfile
        //             '''
                    
        //             sh '''
        //                 docker run --rm -i hadolint/hadolint < frontend/Dockerfile
        //             '''
                    
        //             sh '''
        //                 docker run --rm -v "${PWD}:/repo" -w /repo rhysd/actionlint:latest -color
        //             '''
        //         }
        //     }
        // }
        
        stage('Build and Deploy') {
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
                        IMAGE_TAG=$(echo ${GIT_COMMIT} | cut -c1-8)
                        
                        docker build \
                            -t "${ECR_BACKEND_REPO}:${IMAGE_TAG}" \
                            -t "${ECR_BACKEND_REPO}:latest" \
                            ./backend
                        
                        docker push "${ECR_BACKEND_REPO}:${IMAGE_TAG}"
                        docker push "${ECR_BACKEND_REPO}:latest"
                    '''
                    
                    sh '''
                        IMAGE_TAG=$(echo ${GIT_COMMIT} | cut -c1-8)
                        
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
    }
    
    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
