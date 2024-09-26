This Jenkins pipeline script automates the process of building, pushing, and deploying a Dockerized Node.js application to an AWS EC2 instance. Here’s a breakdown of each section:

### 1. Pipeline Declaration
- **`pipeline { ... }`**: This declares the start of a Jenkins pipeline.

### 2. Agent
- **`agent any`**: This specifies that the pipeline can run on any available Jenkins agent.

### 3. Environment Variables
- **`environment { ... }`**: This block defines environment variables used throughout the pipeline:
  - `AWS_EC2_INSTANCE`: The IP address of the EC2 instance where the application will be deployed.
  - `DOCKER_HUB_CREDENTIAL_ID`: Jenkins credentials ID for Docker Hub login.
  - `DOCKER_IMAGE_NAME`: The name of the Docker image to be built.
  - `TAG`: The tag for the Docker image (default is `latest`).
  - `SSH_KEY_PATH`: Path to the SSH key used for accessing the EC2 instance.

### 4. Stages
Each `stage` represents a specific part of the CI/CD process:

#### Stage 1: Checkout
- **`git branch: 'main', url: 'https://github.com/kamranali111/nodejs_demo_app.git'`**: Clones the code from the specified GitHub repository.

#### Stage 2: Build Docker Image
- **`docker.build("${DOCKER_IMAGE_NAME}:${TAG}")`**: Builds a Docker image using the Dockerfile in the repository and tags it with the specified name and tag.

#### Stage 3: Push Docker Image
- **`withDockerRegistry(...) { ... }`**: Logs into Docker Hub using the provided credentials and pushes the built image to the specified repository.

#### Stage 4: Install Docker on EC2
- This stage checks if Docker is installed on the EC2 instance:
  - If Docker is not found, it updates the package list, installs necessary packages, adds the Docker repository, and installs Docker.

#### Stage 5: Deploy
- **Pull Docker Image**: SSH into the EC2 instance and pulls the newly pushed Docker image.
- **Stop and Remove Existing Container**: Stops and removes any existing container named `node_app` (if it exists).
- **Run Docker Container**: Starts a new Docker container named `node_app`, mapping port 3000 on the host to port 3000 in the container.

### 5. Post Actions
- **`post { ... }`**: Defines actions to take after the pipeline runs:
  - **`always { cleanWs() }`**: Cleans up the workspace, removing files after the job completes.
  - **`success { ... }`**: Displays a message if the pipeline executes successfully.
  - **`failure { ... }`**: Displays a message if the pipeline fails.

### Summary
Overall, this pipeline automates the build and deployment process for a Node.js application in a Docker container on AWS EC2, ensuring that Docker is installed and managing the container lifecycle effectively.
