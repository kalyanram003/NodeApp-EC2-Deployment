pipeline {     
    agent any      

    environment {         
        DOCKER_HUB_CREDENTIAL_ID = 'docker-cred'         
        DOCKER_IMAGE_NAME = 'kamran111/nodejs_demo_app'         
        TAG = 'latest'         
        SSH_KEY_PATH = '/var/jenkins/workspace/test-key.pem'         
        SONAR_PROJECT_KEY = 'NodeApp-EC2-Deployment'
        SONAR_SCANNER = 'sonar-scanner' // SonarQube Scanner installed in Jenkins
        AWS_CREDENTIALS_ID = 'aws-credentials'  // AWS Credentials ID in Jenkins
    }      

    stages {         
        stage('Checkout') {             
            steps {                 
                git branch: 'main', url: 'https://github.com/kamranali111/NodeApp-EC2-Deployment.git'             
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

        // 2. Terraform Apply
        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: env.AWS_CREDENTIALS_ID]]) {
                    script {
                        sh """
                        cd terraform
                        terraform init -no-color
                        terraform apply -auto-approve -no-color
                        """
                        // Capture the instance IP, handling any non-ASCII characters or warnings
                        def instanceIp = sh(script: "terraform output -raw instance_ip", returnStdout: true).trim().replaceAll('[^\\d\\.]+','')
                        if (!instanceIp || instanceIp == "") {
                            error("Failed to capture EC2 instance IP. Please check Terraform outputs.")
                        } else {
                            echo "Filtered EC2 Instance IP: '${instanceIp}'"
                            // Set environment variable for later stages
                            env.AWS_EC2_INSTANCE = instanceIp
                        }
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

        // 5. Install Docker on EC2 (Infrastructure Automation)
        stage('Install Docker on EC2') {             
            steps {                 
                script {                     
                    sh """
                        ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${env.AWS_EC2_INSTANCE} '
                        if ! command -v docker &> /dev/null                         
                        then                             
                            sudo apt-get update &&                             
                            sudo apt-get install -y docker-ce
                            sudo systemctl start docker &&                             
                            sudo systemctl enable docker                         
                        fi
                        '
                    """                 
                }             
            }         
        }

        // 6. Deploy on AWS EC2
        stage('Deploy') {             
            steps {                 
                script {                     
                    sh "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${env.AWS_EC2_INSTANCE} 'sudo docker pull ${DOCKER_IMAGE_NAME}:${TAG}'"
                    sh "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${env.AWS_EC2_INSTANCE} 'sudo docker stop node_app || true && sudo docker rm node_app || true'"
                    sh "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${env.AWS_EC2_INSTANCE} 'sudo docker run -p 3000:3000 --name node_app -d ${DOCKER_IMAGE_NAME}:${TAG}'"
                }             
            }         
        }
    }      
}
