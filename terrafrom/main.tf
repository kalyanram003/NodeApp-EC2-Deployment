# Define the AWS provider
provider "aws" {
  region = "us-east-1"  # Change to your preferred AWS region
}

# Define a key pair for SSH access
resource "aws_key_pair" "deployer_key" {
  key_name   = "deployer-key"
  public_key = file("~/.ssh/id_rsa.pub")  # Path to your public SSH key
}

# Create a security group allowing SSH, HTTP, and port 3000 access
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH, HTTP, and port 3000 traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow port 3000 for Node.js application
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Define the EC2 instance
resource "aws_instance" "web_server" {
  ami           = "ami-0c55b159cbfafe1f0"  # Ubuntu 20.04 AMI (change as needed)
  instance_type = "t2.micro"  # Choose an appropriate instance type

  key_name      = aws_key_pair.deployer_key.key_name
  security_groups = [aws_security_group.allow_ssh_http.name]

  # Define user data to install Docker on EC2 at launch
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              EOF

  tags = {
    Name = "Terraform-EC2-Instance"
  }
}

# Output the public IP and DNS of the instance
output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "instance_public_dns" {
  value = aws_instance.web_server.public_dns
}
