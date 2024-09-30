# Provider configuration
provider "aws" {
  region = "us-east-1"  # Change this to your desired AWS region
}

# AWS EC2 Instance configuration
resource "aws_instance" "node_app_instance" {
  ami           = "ami-0c55b159cbfafe1f0"  # This is an Ubuntu AMI; change based on your region
  instance_type = "t2.micro"

  key_name = "test-key"  # The key pair name, ensure this key is available in AWS

  tags = {
    Name = "NodeAppInstance"
  }
}

# Output the public IP of the created instance
output "instance_ip" {
  value = aws_instance.node_app_instance.public_ip
}
