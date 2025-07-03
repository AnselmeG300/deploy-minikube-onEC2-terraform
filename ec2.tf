terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region     = "us-east-1"
  access_key = "YOUR OWN"
  secret_key = "YOUR OWN"
}


resource "aws_instance" "myec2" {
  ami             = "ami-0aedf6b1cb669b4c7" # CentOS 7
  instance_type   = "t2.medium"              # you can change this
  key_name        = "your-public-key.pem"  # the name of your public key
  security_groups = [aws_security_group.allow_http_https.name]

  root_block_device {
    volume_size = 100 # you can change this value
  }


}

resource "aws_security_group" "allow_http_https" {
  name        = "minikube-sg"
  description = "Allow http and https inbound traffic"

  ingress {
    description = "https from vpc"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http from vpc"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "http from vpc"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh from vpc"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}

resource "aws_eip" "lb" {
  instance = aws_instance.myec2.id
  domain   = "vpc"
  provisioner "local-exec" {
    command = "echo PUBLIC IP: ${self.public_ip} > infos_ec2.txt"
  }
}
