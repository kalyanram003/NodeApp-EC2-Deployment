pipeline {
    agent any
    
    environment {
        AWS_EC2_INSTANCE = '54.82.32.250'
        DOCKER_HUB_CREDENTIAL_ID = 'DOCKER_HUB_CREDENTIAL_ID'
        DOCKER_IMAGE_NAME = 'kamran111/valleyjs'
        TAG = 'latest'
    }

    tools {
        nodejs 'nodejs' // Corrected tool name for Node.js
        jdk 'jdk17' // Corrected tool name for Java 17
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/kamranali111/nodejs_demo_app.git'
            }
        }

    stage('OWASP SCAN'){
        steps{              
            
             dependencyCheck additionalArguments: '', odcInstallation: 'DP-check'
            dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
        }
    }

        stage('Sonar Analysis') {
            steps {
                sh '''
                npm install
                npm install sonarqube-scanner@2.8.0
                npx sonarqube-scanner \
                    -Dsonar.host.url=http://localhost:9000 \
                    -Dsonar.login=squ_25dc760f6eb84e28513e99d622696344d79c3ea8 \
                    -Dsonar.projectKey=test-nodejs
                '''
            }
        }

        stage('Build') {
            steps {
                script {
                    // Build Docker image locally
                    sh "docker build --no-cache -t $DOCKER_IMAGE_NAME ."
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: env.DOCKER_HUB_CREDENTIAL_ID, passwordVariable: 'DOCKER_HUB_PASSWORD', usernameVariable: 'DOCKER_HUB_USERNAME')]) {
                        sh "docker login -u $DOCKER_HUB_USERNAME -p $DOCKER_HUB_PASSWORD"
                    }
                    
                    // Tag the Docker image
                    sh "docker tag $DOCKER_IMAGE_NAME:$TAG $DOCKER_IMAGE_NAME"
                    // Push the Docker image to Docker Hub
                    sh "docker push $DOCKER_IMAGE_NAME"
                }
            }
        }

stage('Trivy'){
steps{
    sh "trivy image kamran111/valleyjs:latest"
}
}
        

        stage('Deploy') {
            steps {
                script {
                    // SSH into the AWS EC2 instance and pull the Docker image
                    sh "ssh -o StrictHostKeyChecking=no -i /var/lib/jenkins/workspace/test-key.pem ubuntu@${AWS_EC2_INSTANCE} 'sudo docker pull $DOCKER_IMAGE_NAME:$TAG'"
                    
                    // Run Docker container on the AWS EC2 instance
                    sh "ssh -o StrictHostKeyChecking=no -i /var/lib/jenkins/workspace/test-key.pem ubuntu@${AWS_EC2_INSTANCE} 'sudo docker run -p 3000:3000 -d $DOCKER_IMAGE_NAME:$TAG'"
                }
            }
        }
    }
}
