terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
}

#create an EC@ instance
resource "aws_instance" "myjenkins_server" {
  ami           = "ami-033fabdd332044f06" 
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.jenkins_security_group.name]
  
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo yum install java-17-amazon-corretto -y
    sudo yum install jenkins -y
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
  EOF
}

# Create default VPC
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

#create s3 bucket
resource "aws_s3_bucket" "mybucket-jenkins" {
  bucket = "terraform-demo-jenk101"
  
  tags = {
    Name = "My-JenkinsServer"
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_jenkins_acl_owner" {
  bucket = aws_s3_bucket.mybucket-jenkins.id
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "s3_jenkins_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.s3_jenkins_acl_owner]

  bucket = aws_s3_bucket.mybucket-jenkins.id
  acl    = "private"
}

#Create security group
resource "aws_security_group" "jenkins_security_group" {
  #Arguments 
  name        = "jenkins_sg_example"
  description = "Allow SSH and HTTP traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #Replace with your IP address
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins_sg"
  }
}
