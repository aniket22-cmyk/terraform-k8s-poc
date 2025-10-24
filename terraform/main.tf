provider "aws" {
  region = var.aws_region
}

resource "aws_instance" "k8s_node" {
  ami           = "ami-0bbdd8c17ed981ef9"  # Ubuntu 22.04 LTS (us-east-1)
  instance_type = "t3.medium"
  key_name      = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              set -e
              export DEBIAN_FRONTEND=noninteractive
              
              # Log everything for debugging
              exec > >(tee -a /var/log/user-data.log)
              exec 2>&1
              
              echo "=== Starting setup at $(date) ==="
              apt-get update
              apt-get install -y python3 curl conntrack socat

              # Install Docker
              echo "Installing Docker..."
              apt-get install -y docker.io
              systemctl enable docker
              systemctl start docker
              usermod -aG docker ubuntu

              # Install kubectl
              curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
              echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
              apt-get update
              apt-get install -y kubectl
              
              # Install Minikube
              curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
              install minikube-linux-amd64 /usr/local/bin/minikube
              
              # Create app directory
              mkdir -p /home/ubuntu/app
              chown -R ubuntu:ubuntu /home/ubuntu/app

              # Start Minikube as ubuntu user with docker driver
              echo "Starting Minikube as ubuntu user..."
              sudo -u ubuntu -i bash << 'INNER_EOF'
              set -e
              export HOME=/home/ubuntu
              # Start Minikube with docker driver (WAIT for it to complete)
              minikube start --driver=docker --kubernetes-version=v1.27.0
              
              # Verify it's running
              echo "Verifying Minikube status..."
              minikube status
              # Wait for all system pods to be ready
              echo "Waiting for Kubernetes to be fully ready..."
              kubectl wait --for=condition=Ready pods --all --all-namespaces --timeout=300s || true
              
              echo "=== Minikube setup complete at $(date) ==="
              INNER_EOF
              
              # Create completion marker
              touch /home/ubuntu/.minikube-ready
              chown ubuntu:ubuntu /home/ubuntu/.minikube-ready
              
              echo "=== User data script completed at $(date) ==="
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