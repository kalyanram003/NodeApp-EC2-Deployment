pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        EKS_CLUSTER_NAME = 'my-eks-cluster'
        DOCKER_IMAGE = 'kamran111/valleyjs:latest'
        DOCKER_CREDENTIALS = 'docker-cred' // Docker Hub credentials in Jenkins
        AWS_CREDENTIALS = 'aws-credentials'
        AWS_CLI_VERSION = '2.17.46'
        EKSCTL_VERSION = '0.190.0'
        PATH = '/var/lib/jenkins/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin'
        SCANNER_HOME = tool 'sonar-scanner' // SonarQube Scanner Home
    }

    stages {
        stage('Clone Repository') {
            steps {
                git url: 'https://github.com/kamranali111/valley_js.git', branch: 'main'
            }
        }

        stage('Clean Up Old Installations') {
            steps {
                script {
                    sh '''
                    if [ -d /var/lib/jenkins/aws-cli ]; then
                        echo "Removing old AWS CLI installation..."
                        rm -rf /var/lib/jenkins/aws-cli
                    fi
                    if [ -f /var/lib/jenkins/bin/eksctl ]; then
                        echo "Removing old eksctl installation..."
                        rm -f /var/lib/jenkins/bin/eksctl
                    fi
                    '''
                }
            }
        }

        stage('Install Tools') {
            steps {
                script {
                    sh '''
                    # Install AWS CLI if not present
                    if ! command -v aws &> /dev/null; then
                        echo "Installing AWS CLI..."
                        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                        unzip awscliv2.zip -d /var/lib/jenkins/aws-cli
                        /var/lib/jenkins/aws-cli/aws/install --install-dir /var/lib/jenkins/aws-cli --bin-dir /var/lib/jenkins/bin
                    else
                        echo "Updating AWS CLI..."
                        /var/lib/jenkins/aws-cli/aws/install --install-dir /var/lib/jenkins/aws-cli --bin-dir /var/lib/jenkins/bin --update
                    fi

                    # Install eksctl if not present
                    if ! command -v eksctl &> /dev/null; then
                        echo "Installing eksctl..."
                        curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
                        mv /tmp/eksctl /var/lib/jenkins/bin/eksctl
                    else
                        echo "eksctl already installed."
                    fi

                    # Verify installations
                    echo "AWS CLI version:"
                    aws --version || true
                    echo "eksctl version:"
                    eksctl version || true
                    '''
                }
            }
        }

        stage('Create EKS Cluster') {
            steps {
                script {
                    withCredentials([aws(credentialsId: AWS_CREDENTIALS)]) {
                        sh '''
                        # Ensure PATH is set for eksctl
                        export PATH=/var/lib/jenkins/bin:$PATH
                        echo "PATH is: $PATH"
                        echo "Checking if EKS cluster already exists..."
                        if eksctl get cluster --name $EKS_CLUSTER_NAME --region $AWS_REGION; then
                            echo "EKS cluster already exists."
                        else
                            echo "Creating EKS cluster..."
                            eksctl create cluster --name $EKS_CLUSTER_NAME --region $AWS_REGION --nodegroup-name standard-workers --node-type t3.medium --nodes 2 --nodes-min 1 --nodes-max 3 --managed
                        fi
                        '''
                    }
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-server') {
                    sh ''' 
                    $SCANNER_HOME/bin/sonar-scanner \
                    -Dsonar.projectName=ValleyJS \
                    -Dsonar.projectKey=valleyjs \
                    -Dsonar.sources=.
                    '''
                }
            }
        }

        stage('Trivy File System Scan') {
            steps {
                sh 'trivy fs --format table -o fs-scan.html .'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.build(DOCKER_IMAGE)
                }
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image --format table -o image-scan.html $DOCKER_IMAGE'
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    withDockerRegistry(credentialsId: DOCKER_CREDENTIALS, url: 'https://index.docker.io/v1/') {
                        docker.image(DOCKER_IMAGE).push()
                    }
                }
            }
        }

        stage('Configure AWS CLI and kubectl') {
            steps {
                script {
                    withCredentials([aws(credentialsId: AWS_CREDENTIALS)]) {
                        sh '''
                        # Ensure PATH is set for AWS CLI
                        export PATH=/var/lib/jenkins/bin:$PATH
                        echo "Running AWS CLI version:"
                        aws --version
                        echo "Updating kubeconfig..."
                        aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME
                        '''
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                script {
                    sh '''
                    # Ensure PATH is set for kubectl
                    export PATH=/var/lib/jenkins/bin:$PATH
                    echo "Running kubectl version:"
                    kubectl version --client
                    echo "Applying Kubernetes manifests..."
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
