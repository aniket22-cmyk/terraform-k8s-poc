provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "k8s_node" {
  ami           = "ami-0bbdd8c17ed981ef9"  # Ubuntu 22.04 LTS (us-east-1)
  instance_type = "t3.medium"
  key_name      = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              set -euxo pipefail
              export DEBIAN_FRONTEND=noninteractive

              # Update and install dependencies
              apt-get update
              apt-get install -y curl apt-transport-https docker.io conntrack socat

              systemctl enable docker
              systemctl start docker

              # Install kubectl
              curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
              echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
              apt-get update
              apt-get install -y kubectl

              # Install Minikube
              curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
              install minikube /usr/local/bin/

              # Create workspace
              mkdir -p /home/ubuntu/app
              chown -R ubuntu:ubuntu /home/ubuntu/app

              # Start Minikube (with Docker driver)
              su - ubuntu -c "minikube start --driver=docker --kubernetes-version=v1.27.0"

              # Adjust ownership of kubeconfig
              chown -R ubuntu:ubuntu /home/ubuntu/.kube /home/ubuntu/.minikube
              EOF


  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "k8s-minikube-poc"
  }
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-minikube-sg"
  description = "Allow SSH and app port"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30001
    to_port     = 30001
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