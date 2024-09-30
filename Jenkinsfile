pipeline {     
    agent any      

    environment {         
        AWS_EC2_INSTANCE = '54.175.239.228'         
        DOCKER_HUB_CREDENTIAL_ID = 'docker-cred'         
        DOCKER_IMAGE_NAME = 'kamran111/nodejs_demo_app'         
        TAG = 'latest'         
        SSH_KEY_PATH = '/var/jenkins/workspace/test-key.pem'         
        SONAR_PROJECT_KEY = 'NodeApp-EC2-Deployment'
        SONAR_SCANNER = 'sonar-scanner' // SonarQube Scanner installed in Jenkins
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



        // 3. Build Docker Image
        stage('Build Docker Image') {             
            steps {                 
                script {                     
                    docker.build("${DOCKER_IMAGE_NAME}:${TAG}")                 
                }             
            }         
        }

  

        // 5. Push Docker Image to DockerHub
        stage('Push Docker Image') {             
            steps {                 
                script {                     
                    withDockerRegistry(credentialsId: env.DOCKER_HUB_CREDENTIAL_ID, url: 'https://index.docker.io/v1/') {                         
                        docker.image("${DOCKER_IMAGE_NAME}:${TAG}").push()                     
                    }                 
                }             
            }         
        }

 

        // 7. Install Docker on EC2 (Infrastructure Automation)
        stage('Install Docker on EC2') {             
            steps {                 
                script {                     
                    sh """
                        ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${AWS_EC2_INSTANCE} '
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

        // 8. Deploy on AWS EC2
        stage('Deploy') {             
            steps {                 
                script {                     
                    sh "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${AWS_EC2_INSTANCE} 'sudo docker pull ${DOCKER_IMAGE_NAME}:${TAG}'"
                    sh "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${AWS_EC2_INSTANCE} 'sudo docker stop node_app || true && sudo docker rm node_app || true'"
                    sh "ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_PATH} ubuntu@${AWS_EC2_INSTANCE} 'sudo docker run -p 3000:3000 --name node_app -d ${DOCKER_IMAGE_NAME}:${TAG}'"
                }             
            }         
        }

       
    }      
}
