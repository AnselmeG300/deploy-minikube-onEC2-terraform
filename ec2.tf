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


  connection {
    type        = "ssh"
    user        = "centos"
    private_key = file("./your-public-key.pem")   # the public key must be in the same folder as ec2.tf
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i -e 's/mirror.centos.org/vault.centos.org/g' -e 's/^#.*baseurl=http/baseurl=http/g' -e 's/^mirrorlist=http/#mirrorlist=http/g' /etc/yum.repos.d/*.repo",

      
      "sudo yum -y update",
      "sudo yum -y install epel-release",
      "sudo yum -y install git libvirt qemu-kvm virt-install virt-top libguestfs-tools bridge-utils",
      "sudo yum install socat -y",
      "sudo yum install -y conntrack",
      "curl -fsSL https://get.docker.com -o install-docker.sh",
      "sh install-docker.sh --dry-run",
      "sudo sh install-docker.sh",
      "sudo usermod -aG docker centos",
      "sudo systemctl start docker",
      "sudo yum -y install wget",
      "sudo wget https://storage.googleapis.com/minikube/releases/v1.32.0/minikube-linux-amd64",
      "sudo chmod +x minikube-linux-amd64",
      "sudo mv minikube-linux-amd64 /usr/bin/minikube",
      "sudo curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.29.0/bin/linux/amd64/kubectl",
      "sudo chmod +x kubectl",
      "sudo mv kubectl  /usr/bin/",
      "sudo su",
      "echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables",
      "exit",
      "sudo systemctl enable docker.service",
      "exec sudo su -l $USER",
      "minikube start –driver=docker --kubernetes-version=v1.28.3",

    ]
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
