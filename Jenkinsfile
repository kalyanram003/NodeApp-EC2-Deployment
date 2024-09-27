pipeline {
    agent any

    environment {
        AWS_EC2_INSTANCE = '54.175.239.228'
        DOCKER_HUB_CREDENTIAL_ID = 'docker-cred'
        DOCKER_IMAGE_NAME = 'kamran111/nodejs_demo_app'
        TAG = 'latest'
        SSH_KEY_PATH = '/var/jenkins/workspace/test-key.pem'
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

        stage('Install Docker on EC2') {
            steps {
                script {
                    // Install Docker on the EC2 instance if not installed
                    sh """
                        ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${AWS_EC2_INSTANCE} '
                        if ! command -v docker &> /dev/null
                        then
                            sudo apt-get update &&
                            sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common &&
                            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
                            sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable" &&
                            sudo apt-get update &&
                            sudo apt-get install -y docker-ce &&
                            sudo systemctl start docker &&
                            sudo systemctl enable docker
                        fi
                        '
                    """
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    // SSH into the AWS EC2 instance and pull the Docker image
                    sh "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${AWS_EC2_INSTANCE} 'sudo docker pull ${DOCKER_IMAGE_NAME}:${TAG}'"

                    // Stop and remove the existing container, if any
                    sh "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${AWS_EC2_INSTANCE} 'sudo docker stop node_app || true && sudo docker rm node_app || true'"

                    // Run Docker container on the AWS EC2 instance
                    sh "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${AWS_EC2_INSTANCE} 'sudo docker run -p 3000:3000 --name node_app -d ${DOCKER_IMAGE_NAME}:${TAG}'"
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
