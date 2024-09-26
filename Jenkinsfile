pipeline {
    agent any

    environment {
        AWS_EC2_INSTANCE = '34.239.117.52'
        DOCKER_HUB_CREDENTIAL_ID = 'docker-cred'
        DOCKER_IMAGE_NAME = 'kamran111/nodejs_demo_app'
        TAG = 'latest'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/kamranali111/nodejs_demo_app.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Build Docker image
                    docker.build("${DOCKER_IMAGE_NAME}:${TAG}")
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: env.DOCKER_HUB_CREDENTIAL_ID, url: 'https://index.docker.io/v1/') {
                        docker.image("${DOCKER_IMAGE_NAME}:${TAG}").push()
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    // Check if Docker is installed on the EC2 instance
                    def checkDocker = sh(script: "ssh -o StrictHostKeyChecking=no -i /var/jenkins/workspace/test-key.pem ubuntu@${AWS_EC2_INSTANCE} 'which docker'", returnStatus: true)
                    
                    if (checkDocker != 0) {
                        error("Docker is not installed on the EC2 instance.")
                    }

                    // Pull the Docker image
                    sh "ssh -o StrictHostKeyChecking=no -i /var/jenkins/workspace/test-key.pem ubuntu@${AWS_EC2_INSTANCE} 'sudo docker pull ${DOCKER_IMAGE_NAME}:${TAG}'"
                    
                    // Stop and remove the existing container, if any
                    sh "ssh -o StrictHostKeyChecking=no -i /var/jenkins/workspace/test-key.pem ubuntu@${AWS_EC2_INSTANCE} 'sudo docker stop node_app || true && sudo docker rm node_app || true'"

                    // Run Docker container on the AWS EC2 instance
                    sh "ssh -o StrictHostKeyChecking=no -i /var/jenkins/workspace/test-key.pem ubuntu@${AWS_EC2_INSTANCE} 'sudo docker run -p 3000:3000 --name node_app -d ${DOCKER_IMAGE_NAME}:${TAG}'"
                }
            }
        }
    }

    post {
        always {
            // Clean up workspace
            cleanWs()
        }

        success {
            echo 'Pipeline executed successfully!'
        }

        failure {
            echo 'Pipeline failed.'
        }
    }
}
