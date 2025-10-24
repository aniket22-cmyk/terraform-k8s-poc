# provider "aws" {
#   region = var.aws_region
# }

# resource "aws_instance" "k8s_node" {
#   ami           = "ami-0bbdd8c17ed981ef9" # Ubuntu 22.04 LTS (us-east-1)
#   instance_type = "t3.medium"
#   key_name      = var.key_name

#   user_data = <<-EOF
#               #!/bin/bash
#               set -euxo pipefail
#               export DEBIAN_FRONTEND=noninteractive

#               exec > >(tee -a /var/log/user-data.log) 2>&1
#               echo "=== Starting setup at $(date) ==="

#               apt-get update
#               apt-get install -y python3 curl conntrack socat apt-transport-https ca-certificates gnupg lsb-release

#               # Install Docker
#               echo "Installing Docker..."
#               apt-get install -y docker.io
#               systemctl enable docker
#               systemctl start docker
#               usermod -aG docker ubuntu

#               # Install kubectl (v1.28)
#               echo "Installing kubectl..."
#               mkdir -p /etc/apt/keyrings
#               curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
#               echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
#               apt-get update -o Acquire::AllowInsecureRepositories=true
#               apt-get install -y --allow-unauthenticated kubectl

#               # Install Minikube
#               echo "Installing Minikube..."
#               curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
#               install minikube-linux-amd64 /usr/local/bin/minikube

#               # Prepare app directory
#               mkdir -p /home/ubuntu/app
#               chown -R ubuntu:ubuntu /home/ubuntu/app

#               echo "=== Launching Minikube as ubuntu user ==="
#               sudo -u ubuntu -i bash <<'INNER_EOF'
#               set -euxo pipefail
#               export HOME=/home/ubuntu
#               export MINIKUBE_HOME=/home/ubuntu/.minikube
#               export KUBECONFIG=/home/ubuntu/.kube/config

#               mkdir -p $MINIKUBE_HOME $HOME/.kube

#               echo "Starting Minikube..."
#               minikube start \
#                 --driver=docker \
#                 --kubernetes-version=v1.28.0 \
#                 --memory=2048 \
#                 --wait=all

#               echo "Verifying Minikube status..."
#               minikube status || true

#               # Wait for certs and kubeconfig
#               echo "Waiting for Minikube kubeconfig and certs to be ready..."
#               for i in {1..60}; do
#                 if [[ -f "$MINIKUBE_HOME/profiles/minikube/client.crt" && \
#                       -f "$MINIKUBE_HOME/profiles/minikube/client.key" && \
#                       -f "$MINIKUBE_HOME/ca.crt" && \
#                       -s "$KUBECONFIG" ]]; then
#                   echo "✅ Minikube kubeconfig and certs are ready."
#                   break
#                 fi
#                 echo "Waiting for kubeconfig files... ($i/60)"
#                 sleep 10
#               done

#               echo "Fixing kubeconfig context paths..."
#               minikube update-context

#               echo "Waiting for Kubernetes system pods..."
#               kubectl wait --for=condition=Ready pods --all --all-namespaces --timeout=300s || true

#               echo "Verifying cluster..."
#               kubectl get nodes || true

#               echo "=== Minikube setup complete ==="
#               INNER_EOF

#               touch /home/ubuntu/.minikube-ready
#               chown ubuntu:ubuntu /home/ubuntu/.minikube-ready

#               echo "=== User data script completed at $(date) ==="
#               EOF

#   vpc_security_group_ids = [aws_security_group.k8s_sg.id]

#   tags = {
#     Name = "k8s-minikube-poc"
#   }
# }

# resource "aws_security_group" "k8s_sg" {
#   name        = "k8s-minikube-sg"
#   description = "Allow SSH and app ports"

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 8443
#     to_port     = 8443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     from_port   = 30000
#     to_port     = 32767
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }
provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-minikube-sg"
  description = "Allow SSH and app ports"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
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

resource "aws_instance" "k8s_node" {
  ami           = "ami-0bbdd8c17ed981ef9" # Ubuntu 22.04 LTS (us-east-1)
  instance_type = "t3.medium"
  key_name      = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "k8s-minikube-poc"
  }

  user_data = <<EOF
#!/bin/bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive

exec > >(tee -a /var/log/user-data.log) 2>&1
echo "=== Starting setup at $(date) ==="

# Install dependencies
apt-get update
apt-get install -y python3 curl conntrack socat apt-transport-https ca-certificates gnupg lsb-release docker.io

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# Install kubectl
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" > /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y --allow-unauthenticated kubectl

# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

# Prepare directories
mkdir -p /home/ubuntu/app /home/ubuntu/.kube /home/ubuntu/.minikube
chown -R ubuntu:ubuntu /home/ubuntu

# Create Minikube setup script
cat <<'EOT' > /tmp/minikube-setup.sh
#!/bin/bash
set -euxo pipefail

export HOME=/home/ubuntu
export MINIKUBE_HOME=$HOME/.minikube
export KUBECONFIG=$HOME/.kube/config

mkdir -p $MINIKUBE_HOME $HOME/.kube

echo "Starting Minikube with docker driver..."
# Use docker driver instead of none - this works out of the box
minikube start --driver=docker --kubernetes-version=v1.28.0 --memory=2048 --wait=all

echo "Updating kubeconfig context..."
minikube update-context

echo "Waiting for kubeconfig and certs..."
for i in $(seq 1 60); do
  if [[ -f "$MINIKUBE_HOME/profiles/minikube/client.crt" &&
        -f "$MINIKUBE_HOME/profiles/minikube/client.key" &&
        -f "$MINIKUBE_HOME/ca.crt" &&
        -s "$KUBECONFIG" ]]; then
    echo "✅ Minikube kubeconfig and certs ready"
    break
  fi
  echo "Waiting... ($i/60)"
  sleep 10
done

chmod -R 600 $MINIKUBE_HOME/profiles/minikube/*.key 2>/dev/null || true
chown -R ubuntu:ubuntu $MINIKUBE_HOME $HOME/.kube

echo "Waiting for Kubernetes system pods..."
kubectl wait --for=condition=Ready pods --all --all-namespaces --timeout=300s || true
kubectl get nodes -o wide
EOT

chmod +x /tmp/minikube-setup.sh

# Run the setup script as ubuntu user (docker driver requires non-root)
su - ubuntu -c "bash /tmp/minikube-setup.sh"

# Mark ready
touch /home/ubuntu/.minikube-ready
chown ubuntu:ubuntu /home/ubuntu/.minikube-ready

echo "=== Setup complete at $(date) ==="
EOF
}