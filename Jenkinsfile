pipeline {
    agent any

    environment {
        AWS_EC2_INSTANCE = '13.233.212.129'
        DOCKER_HUB_CREDENTIAL_ID = 'devopsdemo'
        DOCKER_IMAGE_NAME = 'kamran111/nodejs_demo_app'
        TAG = 'latest'
        SSH_KEY_PATH = 'C:\Users\ASUS\Downloads\dev-prac.pem'
        SONAR_PROJECT_KEY = 'NodeApp-EC2-Deployment'
        SONAR_SCANNER = 'sonar-scanner' // SonarQube Scanner installed in Jenkins
        AWS_CREDENTIALS_ID = 'aws-credentials'  // AWS Credentials ID in Jenkins
        INSTANCE_IP = '' // Declare as environment variable for global access
        PUBLIC_IP = '' // Variable to store the public IP of the EC2 instance
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/kalyanram003/NodeApp-EC2-Deployment.git'
            }
        }

        // 1. Code Quality & Security Analysis
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    script {
                        sh """
                        ${SONAR_SCANNER} \
                        -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                        -Dsonar.sources=.
                        """
                    }
                }
            }
        }

        // 2. Terraform Init and Apply
        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID]]) {
                    script {
                        sh """
                        cd terraform
                        terraform init
                        terraform apply -auto-approve
                        """
                        // Capture the instance IP output and assign it to the environment variable
                        env.INSTANCE_IP = sh(script: "cd terraform && terraform output -raw -no-color instance_ip", returnStdout: true).trim()
                        echo "EC2 Instance IP: ${env.INSTANCE_IP}"
                    }
                }
            }
        }

        // 3. Build Docker Image
        stage('Build Docker Image') {
            steps {
                script {
                    docker.build("${DOCKER_IMAGE_NAME}:${TAG}")
                }
            }
        }

        // 4. Push Docker Image to DockerHub
        stage('Push Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: env.DOCKER_HUB_CREDENTIAL_ID, url: 'https://index.docker.io/v1/') {
                        docker.image("${DOCKER_IMAGE_NAME}:${TAG}").push()
                    }
                }
            }
        }

        // 5. Install Docker on EC2 and fetch public IP
        stage('Install Docker on EC2') {
            steps {
                script {
                    // Use the globally captured instance IP
                    sh """
                        ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${env.INSTANCE_IP} '
                        if ! command -v docker &> /dev/null
                        then
                            sudo apt-get update &&
                            sudo apt-get install -y docker-ce
                            sudo systemctl start docker &&
                            sudo systemctl enable docker
                        fi

                        # Get the public IP of the EC2 instance and save it to PUBLIC_IP
                        PUBLIC_IP=\$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
                        echo "Public IP of EC2 Instance: \$PUBLIC_IP"
                        '
                    """
                }
            }
        }

        // 6. Deploy on AWS EC2
        stage('Deploy') {
            steps {
                script {
                    sh "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${env.INSTANCE_IP} 'sudo docker pull ${DOCKER_IMAGE_NAME}:${TAG}'"
                    sh "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${env.INSTANCE_IP} 'sudo docker stop node_app || true && sudo docker rm node_app || true'"
                    sh "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${env.INSTANCE_IP} 'sudo docker run -p 3000:3000 --name node_app -d ${DOCKER_IMAGE_NAME}:${TAG}'"
                }
            }
        }
    }
}
